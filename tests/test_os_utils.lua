local lunit = require("lunit")
local os_utils = require("nginx_upload.os_utils")

local pairs = pairs
local print = print


module("p", lunit.testcase)


function test_basic_join()
    lunit.assert_equal('/bar/baz', os_utils.joinpath("/foo", "bar", "/bar", "baz"))
    lunit.assert_equal("/foo/bar/baz", os_utils.joinpath("/foo", "bar", "baz"))
    lunit.assert_equal("/foo/bar/baz/", os_utils.joinpath("/foo/", "bar/", "baz/"))
    lunit.assert_equal("/bar/baz", os_utils.joinpath("/foo", "bar", "/bar", "baz"))
    lunit.assert_equal("/foo/bar/baz", os_utils.joinpath("/foo", "bar", "baz"))
    lunit.assert_equal("/foo/bar/baz/", os_utils.joinpath("/foo/", "bar/", "baz/"))
end


function test_join_with_nils()
    lunit.assert_equal('/bar/baz', os_utils.joinpath("/foo", nil, "bar", "/bar", "baz"))
    lunit.assert_equal('/foo', os_utils.joinpath("/foo", nil))
end


function test_join_with_empty_string()
    lunit.assert_equal('/bar/baz', os_utils.joinpath("", "bar", "/bar", "baz"))
    lunit.assert_equal('/foo/', os_utils.joinpath("/foo", ""))
    lunit.assert_equal('', os_utils.joinpath("", ""))
end
