local lunit = require("lunit")
local http_utils = require("nginx_upload.http_utils")

local table = table

module("p", lunit.testcase)


-- tests taken from here http://greenbytes.de/tech/tc2231/
function test_inline_only()
    disp_type, disp_params = http_utils.parse_content_disposition("inline")
    lunit.assert_equal("inline", disp_type)
end

function test_inline_only_quoted()
    disp_type, disp_params = http_utils.parse_content_disposition('"inline"')
    lunit.assert_equal(nil, disp_type)
end

function test_inline_with_ascii_filename()
    local header = 'inline; filename="foo.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('inline', disp_type)
    lunit.assert_equal('foo.html', disp_params['filename'])
end

function test_inline_with_filename_attachment()
    local header = 'inline; filename="Not an attachment!"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('inline', disp_type)
    lunit.assert_equal('Not an attachment!', disp_params['filename'])
end

function test_attachment_only()
    local header = 'attachment'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal("attachment", disp_type)
end

function test_attachment_only_uppercase()
    local header = 'ATTACHMENT'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal("attachment", disp_type)
end

function test_attachment_with_ascii_filename()
    local header = 'attachment; filename="foo.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal('foo.html', disp_params['filename'])
end

function test_attachment_with_ascii_filename_25()
    local header = 'attachment; filename="0000000000111111111122222"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal('0000000000111111111122222', disp_params['filename'])
end

function test_attachment_with_ascii_filename_35()
    local header = 'attachment; filename="00000000001111111111222222222233333"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal('00000000001111111111222222222233333',
                       disp_params['filename'])
end

function test_attachment_with_ascii_filename_escaped_quote()
    local header = 'attachment; filename="\\"quoting\\" tested.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal('\"quoting\" tested.html', disp_params['filename'])
end

function test_attachment_with_quoted_semicolon()
    local header = 'attachment; filename="Here\'s a semicolon;.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal('Here\'s a semicolon;.html', disp_params['filename'])
end

function test_attachment_with_filename_and_ext_param()
    local header = 'attachment; foo="bar"; filename="foo.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal('foo.html', disp_params['filename'])
    lunit.assert_equal('bar', disp_params['foo'])
end

function test_attachment_with_filename_and_ext_escaped()
    local header = 'attachment; foo="\\"\\\\";filename="foo.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal('"\\\\', disp_params['foo'])
    lunit.assert_equal('foo.html', disp_params['filename'])
end

function test_attachment_with_filename_uppercase()
    local header = 'attachment; FILENAME="foo.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal('foo.html', disp_params['filename'])
end

function test_attachment_with_ascii_filename_nonquoted()
    local header = 'attachment; filename=foo.html'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal('foo.html', disp_params['filename'])
end

function test_attachment_with_filename_token_singlequotes()
    local header = "attachment; filename='foo.html'"
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal("'foo.html'", disp_params['filename'])
end

function test_attachment_with_iso_filename_plain()
    local header = "attachment; filename=foo-%41.html"
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal("foo-%41.html", disp_params['filename'])
end

function test_attachment_with_filename_using_percent()
    local header = 'attachment; filename="%50.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal("%50.html", disp_params['filename'])
end

function test_attachment_with_filename_percent_and_iso()
    local header = 'attachment; filename="foo-%41.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal("foo-%41.html", disp_params['filename'])
end

function test_attachment_with_filename_raw_percent_encoding_long()
    local header = 'attachment; filename="foo-%c3%a4-%e2%82%ac.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal("foo-%c3%a4-%e2%82%ac.html", disp_params['filename'])
end

function test_attachment_with_ascii_filename_whitespace1()
    local header = 'attachment; filename ="foo.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal("foo.html", disp_params['filename'])
end

function test_attachment_confused_param()
    local header = 'attachment; xfilename=foo.html'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal("foo.html", disp_params['xfilename'])
end

function test_attachment_absolute_path()
    local header = 'attachment; filename="/foo.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal("/foo.html", disp_params['filename'])
end

function test_attachment_backspace_win()
    local header = 'attachment; filename="\\foo.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal("\\foo.html", disp_params['filename'])
end

function test_attachment_cdate()
    local header =
              'attachment; creation-date="Wed, 12 Feb 1997 16:29:51 -0500"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal("Wed, 12 Feb 1997 16:29:51 -0500",
                       disp_params['creation-date'])
end

function test_attachment_mdate()
    local header =
             'attachment; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal("Wed, 12 Feb 1997 16:29:51 -0500",
                       disp_params['modification-date'])
end

function test_dispext()
    local header = 'foobar'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('foobar', disp_type)
end

function test_dispext_bad_filename()
    local header = 'attachment; example="filename=example.txt"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal('filename=example.txt', disp_params['example'])
end

function test_attachment_new_and_filename()
    local header = 'attachment; foobar=x; filename="foo.html"'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal('foo.html', disp_params['filename'])
    lunit.assert_equal('x', disp_params['foobar'])
end

function test_attachment_new_and_filename_encoded()
    local header = 'attachment; filename="=?ISO-8859-1?Q?foo-=E4.html?="'
    disp_type, disp_params = http_utils.parse_content_disposition(header)
    lunit.assert_equal('attachment', disp_type)
    lunit.assert_equal('=?ISO-8859-1?Q?foo-=E4.html?=',
                       disp_params['filename'])
end

-- this is not implemented
-- function test_attachment_with_iso_filename_2231iso()
    -- local header = 'attachment; filename*=iso-8859-1\'\'foo-%E4.html'
    -- disp_type, disp_params = http_utils.parse_content_disposition(header)
    -- lunit.assert_equal('attachment', disp_type)
    -- lunit.assert_equal('foo-ä.html', disp_params['filename*'])
-- end

-- this fails because rfc forbids non ascii token
-- function test_attachment_with_iso_filename_plain()
    -- local header = "attachment; filename=foo-ä.html"
    -- disp_type, disp_params = http_utils.parse_content_disposition(header)
    -- lunit.assert_equal('attachment', disp_type)
    -- lunit.assert_equal("foo-ä.html", disp_params['filename'])
-- end

-- this fails because matching stops at first invalid char without aborting,
-- thus returning foo
-- function test_attachment_with_token_filename_comma_nonquoted()
    -- local header = 'attachment; filename=foo,bar.html'
    -- disp_type, disp_params = http_utils.parse_content_disposition(header)
    -- lunit.assert_equal('attachment', disp_type)
    -- lunit.assert_equal(nil, disp_params['filename'])
-- end


-- tests for get_boundary_from_content_type_header()

function test_get_boundary_from_content_type_header()
    local header = 'multipart/mixed; boundary=gc0p4Jq0M2Yt08jU534c0p'
    local boundary = http_utils.get_boundary_from_content_type_header(header)
    lunit.assert_equal('gc0p4Jq0M2Yt08jU534c0p', boundary)
end


function test_get_quoted_boundary_from_content_type_header()
    local header = 'multipart/form-data; boundary="gc0p4Jq0M2Yt08jU534c0p"'
    local boundary = http_utils.get_boundary_from_content_type_header(header)
    lunit.assert_equal('gc0p4Jq0M2Yt08jU534c0p', boundary)
end


function test_get_boundary_from_content_type_header_multiple_params_quoted()
    local header = 'multipart/form-data; foo="bar"; boundary="gc0p4Jq0M2Yt08jU534c0p"'
    local boundary = http_utils.get_boundary_from_content_type_header(header)
    lunit.assert_equal('gc0p4Jq0M2Yt08jU534c0p', boundary)
end


function test_get_boundary_from_content_type_header_multiple_params()
    local header = 'multipart/form-data; foo=bar; boundary=gc0p4Jq0M2Yt08jU534c0p'
    local boundary = http_utils.get_boundary_from_content_type_header(header)
    lunit.assert_equal('gc0p4Jq0M2Yt08jU534c0p', boundary)
end


-- tests for form_multipart_body
function test_form_multipart_body_with_value_only()
    local boundary = 'test_boundary'
    local part_one = {['value']='test'}
    local parts = {['part_name'] = {part_one}}
    local body = http_utils.form_multipart_body(parts, boundary)
    local expected_body = table.concat({'--test_boundary\r\n',
              'Content-Disposition: form-data; name="part_name"\r\n',
              '\r\n',
              'test\r\n',
              '--test_boundary--\r\n'
          })
    lunit.assert_equal(expected_body, body)
end


function test_form_multipart_body_with_filename()
    local boundary = 'test_boundary'
    local part_two = {['filename']='fname',
                      ['filename']='fname',
                      ['content_type']='ctype',
                      ['size']='1234',
                      ['filepath']='fpath'}
    local parts = {['part_name'] = {part_one}, ['file_part_name'] = {part_two}}
    local body = http_utils.form_multipart_body(parts, boundary)
    local expected_body = table.concat({'--test_boundary\r\n',
              'Content-Disposition: form-data; name="file_part_name.name"\r\n',
              '\r\n',
              'fname\r\n',
              '--test_boundary\r\n',
              'Content-Disposition: form-data; name="file_part_name.path"\r\n',
              '\r\n',
              'fpath\r\n',
              '--test_boundary\r\n',
              'Content-Disposition: form-data; name="file_part_name.content-type"\r\n',
              '\r\n',
              'ctype\r\n',
              '--test_boundary\r\n',
              'Content-Disposition: form-data; name="file_part_name.size"\r\n',
              '\r\n',
              '1234\r\n',
              '--test_boundary--\r\n'
          })
    lunit.assert_equal(expected_body, body)
end


function test_form_multipart_body_with_two_parts_with_same_name()
    local boundary = 'test_boundary'
    local part_one = {['value']='test'}
    local part_two = {['value']='test2'}
    local parts = {['part_name'] = {part_one, part_two}}
    local body = http_utils.form_multipart_body(parts, boundary)

    -- two different bodies to not rely on ordering
    local expected_body1 = table.concat({'--test_boundary\r\n',
              'Content-Disposition: form-data; name="part_name"\r\n',
              '\r\n',
              'test\r\n',
              '--test_boundary\r\n',
              'Content-Disposition: form-data; name="part_name"\r\n',
              '\r\n',
              'test2\r\n',
              '--test_boundary--\r\n'
          })
    local expected_body2 = table.concat({'--test_boundary\r\n',
              'Content-Disposition: form-data; name="part_name"\r\n',
              '\r\n',
              'test\r\n',
              '--test_boundary\r\n',
              'Content-Disposition: form-data; name="part_name"\r\n',
              '\r\n',
              'test2\r\n',
              '--test_boundary--\r\n'
          })
    if body ~= expected_body1 and body ~= expected_body2 then
        lunit.fail('Unexpected body: "'..body..'"')
    end
end
