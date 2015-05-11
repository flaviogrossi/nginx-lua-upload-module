local lpeg = require("lpeg")


local M = {}


-- rfc 5987 sec. 3.2.1
-- mime-charset = 1*mime-charsetc
-- mime-charsetc = ALPHA / DIGIT
--                 / "!" / "#" / "$" / "%" / "&"
--                 / "+" / "-" / "^" / "_" / "`"
--                 / "{" / "}" / "~"
local mime_charset = (lpeg.R("09", "az", "AZ") + lpeg.S("!#$%&+-^_`{}/~"))^1

-- attr-char     = ALPHA / DIGIT
--                 / "!" / "#" / "$" / "&" / "+" / "-" / "."
--                 / "^" / "_" / "`" / "|" / "~"
local attr_char = lpeg.R("09", "az", "AZ") + lpeg.S("!#$&+-.^_`|~")

local hexdigit = lpeg.R("09", "af", "AF")

local pct_encoded = lpeg.S("%") * hexdigit * hexdigit

local value_chars = (pct_encoded + attr_char)^0

local language = lpeg.R("09", "az", "AZ") + lpeg.S("-")

local lwsp    = lpeg.S(" \t")

local ext_value = mime_charset * lwsp^0 * lpeg.S("'")
                  * language^0 * lpeg.S("'") * lwsp^0 * value_chars

-- rfc rfc2616 sec. 2.2
-- TEXT           = <any OCTET except CTLs, but including LWS>
-- ctext          = <any TEXT excluding "(" and ")">
-- CTL            = <any US-ASCII control character (octets 0 - 31)
--                   and DEL (127)>
local ctl = lpeg.R("\000\031")

-- TEXT           = <any OCTET except CTLs, but including LWS>
local text = lpeg.P(1) - (ctl - lpeg.S("\t"))
-- ctext          = <any TEXT excluding "(" and ")">
local ctext = text - lpeg.R("()")

-- quoted-string  = ( <"> *(qdtext | quoted-pair ) <"> )
-- qdtext         = <any TEXT except <">>
-- quoted-pair    = "\" CHAR
local qdtext =  ctext - lpeg.S('"')
local quoted_pair = lpeg.P('\\"') / '"'
local escaped_bs = lpeg.P('\\\\')
local quoted_string = lpeg.P('"')
                      * lpeg.Cs((escaped_bs + quoted_pair + qdtext)^0)
                      * lpeg.P('"')

-- token          = 1*<any CHAR except CTLs or separators>
-- separators     = "(" | ")" | "<" | ">" | "@"
--                  | "," | ";" | ":" | "\" | <">
--                  | "/" | "[" | "]" | "?" | "="
--                  | "{" | "}" | SP | HT
local separators = lpeg.S("()<>@,;:\\\"/[]?={} \t")
local token = (lpeg.R("\032\126") - separators)^1

-- ext-token           = <the characters in token, followed by "*">
local ext_token = token * lpeg.P("*")


function M.parse_content_disposition(header_value)
    -- parse a content disposition header (only the value part) and returns a
    -- tuple (disp_type, disp_params) where disp_type is the disposition type
    -- and disp_params is a table of the disposition params
    --
    -- E.g.:
    -- local typ, parms = 'attachment; foo="bar"; filename="foo.html"'
    -- -- typ --> "attachment"
    -- -- parms --> { ['filename']='foo.html', ['foo']='bar' }

    local filename_param = lpeg.P("filename") + lpeg.P("filename*")
                           + (lpeg.P("FILENAME") / "filename")
                           + (lpeg.P("FILENAME*") / "filename")
    local param_name = filename_param + token + ext_token
    local param_value = quoted_string + lpeg.C(token) + lpeg.C(ext_value)
    local disp_param = lpeg.Cs(param_name) * lwsp^0 * lpeg.P("=")
                       * lwsp^0 * param_value
    local disp_params = lwsp^0 * lpeg.P(";") * lwsp^0 * lpeg.Cg(disp_param)
    local disp_type = lpeg.P("inline") + lpeg.P("attachment") + token

    local function accumulate_params(t, k, v)
        t[k] = v
        return t
    end

    local hval = lwsp^0 * lpeg.C(disp_type) * lpeg.Cf(lpeg.Ct("")
                 * disp_params^0, accumulate_params)

    local disp_type, disp_params = lpeg.match(hval, header_value)
    if disp_type then
        disp_type = disp_type:lower()
    end
    return disp_type, disp_params
end


function M.get_boundary_from_content_type_header(header_value)
    -- parse a content type header (only the value part) and returns the
    -- boundary parameter
    --
    -- E.g.:
    -- local boundary = 'Content-Type: multipart/mixed; boundary=gc0p4Jq0M2Y'
    -- -- boundary --> "gc0p4Jq0M2Y"

    local media_type = token * lpeg.P('/') * token
    local value = quoted_string + lpeg.C(token)
    local param = lpeg.Cs(token) * lwsp^0 * lpeg.P("=") * lwsp^0 * value
    local params = lwsp^0 * lpeg.P(";") * lwsp^0 * lpeg.Cg(param)

    local function accumulate_params(t, k, v)
        t[k] = v
        return t
    end

    local hval = lwsp^0 * lpeg.C(media_type) * lpeg.Cf(lpeg.Ct("")
                 * params^0, accumulate_params)

    local media_type, params = lpeg.match(hval, header_value)
    return params['boundary']
end


function M.form_multipart_body(parts, boundary)
    -- forms a valid multipart/form-data body with the given boundary and parts

    local body = {}
    local crlf = '\r\n'
    local dcrlf = crlf..crlf
    for part_name, part in pairs(parts) do
        table.insert(body, '--'..boundary..crlf)
        if not part['filename'] then
            table.insert(body,
              'Content-Disposition: form-data; name="'..part_name..'"'..dcrlf)
            table.insert(body, part['value']..crlf)
        else
            table.insert(body,
                'Content-Disposition: form-data; name="name"'..dcrlf)
            table.insert(body, part['filename']..crlf)
            table.insert(body, '--'..boundary..crlf)
            table.insert(body,
                'Content-Disposition: form-data; name="path"'..dcrlf)
            table.insert(body, part['filepath']..crlf)
            table.insert(body, '--'..boundary..crlf)
            table.insert(body,
                'Content-Disposition: form-data; name="content-type"'..dcrlf)
            table.insert(body, part['content_type']..crlf)
            table.insert(body, '--'..boundary..crlf)
            table.insert(body,
                'Content-Disposition: form-data; name="size"'..dcrlf)
            table.insert(body, part['size']..crlf)
        end
    end
    table.insert(body, '--'..boundary..'--'..crlf)
    return table.concat(body)
end


return M
