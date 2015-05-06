local lunit = require("lunit")
local string_utils = require("nginx_upload.string_utils")

local pairs = pairs
local print = print


module("p", lunit.testcase)


function test_basic_split()
    local t = string_utils.split('one,two,three', ',')
    local expected = {'one', 'two', 'three'}
    for i, v in pairs(expected) do
        lunit.assert_equal(v, t[i])
    end
end

function test_split_with_no_matches()
    local t = string_utils.split('onetwothree', ',')
    local expected = {'onetwothree'}
    for i, v in pairs(expected) do
        lunit.assert_equal(v, t[i])
    end
end

function test_split_with_empty_input()
    local t = string_utils.split('', ',')
    local expected = {''}
    for i, v in pairs(expected) do
        lunit.assert_equal(v, t[i])
    end
end

function test_split_with_leading_separator()
    local t = string_utils.split(',one,two', ',')
    local expected = {'', 'one', 'two'}
    for i, v in pairs(expected) do
        lunit.assert_equal(v, t[i])
    end
end

function test_split_with_trailing_separator()
    local t = string_utils.split('one,two,', ',')
    local expected = {'one', 'two', ''}
    for i, v in pairs(expected) do
        lunit.assert_equal(v, t[i])
    end
end

function test_split_with_empty_field()
    local t = string_utils.split('one,,two', ',')
    local expected = {'one', '', 'two'}
    for i, v in pairs(expected) do
        lunit.assert_equal(v, t[i])
    end
end
