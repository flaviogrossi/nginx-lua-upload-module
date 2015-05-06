local lunit = require("lunit")
local string_utils = require("nginx_upload.string_utils")

local pairs = pairs
local print = print


module("p", lunit.testcase)


function assert_table_length(expected_len, t, message)
    local count = 0
    for i, v in pairs(t) do
        count = count + 1
    end
    return lunit.assert_equal(expected_len, count, message)
end


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

function test_basic_strip()
    local s = string_utils.strip('  one two\t')
    lunit.assert_equal('one two', s)
end

function test_strip_with_no_ws()
    local s = string_utils.strip('one two')
    lunit.assert_equal('one two', s)
end

function test_strip_with_no_ws()
    local s = string_utils.strip('one two')
    lunit.assert_equal('one two', s)
end

function test_strip_with_empty_input()
    local s = string_utils.strip('')
    lunit.assert_equal('', s)
end

function test_basic_enumerate_from_string_range()
    local t = string_utils.enumerate_from_string_range('10,20,30-32')
    local expected = {10, 20, 30, 31, 32}

    assert_table_length(#expected, t)
    for _, v in pairs(expected) do
        lunit.assert_true(t[v])
    end

    local t = string_utils.enumerate_from_string_range('30-32,10,20')
    local expected = {10, 20, 30, 31, 32}

    assert_table_length(#expected, t)
    for _, v in pairs(expected) do
        lunit.assert_true(t[v])
    end
end

function test_enumerate_from_string_range_invalid_returns_empty()
    assert_table_length(0, string_utils.enumerate_from_string_range(''))
    assert_table_length(0, string_utils.enumerate_from_string_range('a'))
    assert_table_length(0,
                        string_utils.enumerate_from_string_range('10+12+13'))
    assert_table_length(0,
                        string_utils.enumerate_from_string_range('13-w'))
end

function test_enumerate_from_string_range_only_single_els()
    local t = string_utils.enumerate_from_string_range('10,20,30')
    local expected = {10, 20, 30}

    assert_table_length(#expected, t)
    for _, v in pairs(expected) do
        lunit.assert_true(t[v])
    end
end

function test_enumerate_from_string_range_invalid_range_is_ignored()
    local t = string_utils.enumerate_from_string_range('10,13-12')
    local expected = {10}
    assert_table_length(#expected, t)
    for _, v in pairs(expected) do
        lunit.assert_true(t[v])
    end
end
