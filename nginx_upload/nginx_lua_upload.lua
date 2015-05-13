if ngx.var.package_path then
    package.path = ngx.var.package_path .. ";" .. package.path
end

local posix = require "posix"
local upload = require "resty.upload"
local http_utils = require "nginx_upload.http_utils"
local string_utils = require "nginx_upload.string_utils"

local chunk_size = 4096
local form = upload:new(chunk_size)
local parts = {}
local backend_url = ngx.var.backend_url
local response
local upload_cleanup = ngx.var.upload_cleanup
if not upload_cleanup then
    upload_cleanup = ''
end


if (backend_url == nil or backend_url == "") then
    ngx.log(ngx.ERR, "No $backend_url set in nginx.conf. Failing request.")
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

ngx.log(ngx.DEBUG, "backend_url is \"", backend_url, "\"")

local boundary = http_utils.get_boundary_from_content_type_header(
                                        ngx.req.get_headers()["Content-Type"])

if not boundary then
    ngx.log(ngx.ERR, "No boundary from content-type header (\""
            .. ngx.req.get_headers()["Content-Type"] .. "\")")
    ngx.exit(ngx.HTTP_BAD_REQUEST)
end


local current_content_type -- content type for the current part
local current_filename -- filename for the current part
local current_name -- name for the current part
local current_path -- filepath for the current part (if saved to disk)
local file_descriptor  -- file descriptor for the current part
                       -- (if saved to disk)

local value_buffer = {} -- used to concatenate body when not saving to disk


while true do
    local typ, res, err = form:read()

    if not typ then
        ngx.log(ngx.ERR, "Failed to read: ", err)
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end

    if typ == "header" then
        local field
        local value
        local line
        field, value, line = res[1], res[2], res[3]

        ngx.log(ngx.DEBUG, "Got header \"", line, "\"")

        -- if filename, save to disk, else, save to arguments
        if field:lower() == "content-disposition" then
            local disp_type, disp_params =
                                  http_utils.parse_content_disposition(value)
            if disp_type == "form-data" then
                current_filename = disp_params['filename']
                current_name = disp_params['name']
                if current_filename and current_filename ~= '' then
                    current_path = os.tmpname()
                    ngx.log(ngx.DEBUG, "Saving body to \"", current_path, "\"")
                    if current_path then
                        file_descriptor = io.open(current_path, "w+")
                        if not file_descriptor then
                            ngx.say("failed to open file ", current_path)
                            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
                            return
                        end
                    end
                end
            end
        elseif field:lower() == "content-type" then
            current_content_type = value
        end


    elseif typ == "body" then
        if file_descriptor then
            if not file_descriptor:write(res) then
                ngx.log(ngx.ERR, "Failed to write to file")
                ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
            end
        else
            table.insert(value_buffer, res)
        end

    elseif typ == "part_end" then
        local part = {}

        if file_descriptor then
            part['size'] = file_descriptor:seek("end")
            file_descriptor:close()
            posix.chmod(current_path, 'rw-rw----')
        end
        if not part['size'] then
            part['size'] = "0"
        end
        file_descriptor = nil

        part['content_type'] = current_content_type
        part['filename'] = current_filename
        part['filepath'] = current_path
        part['value'] = table.concat(value_buffer)

        parts[current_name] = part

        current_filename = nil
        current_content_type = nil
        current_name = nil
        current_path = nil
        value_buffer = {}

    elseif typ == "eof" then
        break

    else
        -- do nothing
    end
end


-- proxy request to backend_url and return response
local cleanup_codes = string_utils.enumerate_from_string_range(upload_cleanup)
local body = http_utils.form_multipart_body(parts, boundary)

local response = ngx.location.capture(backend_url,
                                      { method=ngx.HTTP_POST, body=body })
ngx.status = response.status
if cleanup_codes[response.status] then
    -- remove temporary uploaded files
    for _, part in pairs(parts) do
        if part['filepath'] then
            os.remove(part['filepath'])
        end
    end
end

for k, v in pairs(response.header) do
    ngx.header[k] = v
end
ngx.print(response.body)
return ngx.OK
