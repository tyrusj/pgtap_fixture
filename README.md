# pgTAP_fixture
This PostgreSQL extension is intended to be used with the [pgTAP](https://pgtap.org/) extension for creating tests. It has the following features:
- Allows creation of fixtures within fixtures
- Allows per-fixture definition of scripts to run before or after the fixture.
- Allows creation of tests that accept parameters.

## Supported PostgreSQL versions
- PostgreSQL 17

## Installation

To install pgTAP_fixture, download a zip file from the releases, extract it, and run `make install`. To uninstall it, run `make uninstall`.

``` shell
# Install
tar xzvf ./pgtap_fixture-0.0.1.tar.gz
cd pgtap_fixture-0.0.1
make install
```
``` shell
# Uninstall
cd pgtap_fixture-0.0.1
make uninstall
```

## Usage

### Creating tests

Test functions must execute [pgTAP](https://pgtap.org/) functions and return their results as a set of text. Two kinds of tests are supported:
-   Those that take no arguments.
-   Those that take two arguments: the test parameters, and the test description.

Tests that take no arguments are no different from tests that can be run with the pgTAP extension alone without this extension.
``` sql
create function my_schema.test_without_arguments() returns setof text as $$
begin
    return query select pgtap.ok(true);
end;$$ language plpgsql;
```

If a test takes arguments, and if data has been added for the test with the `add_test_data` function, then it will be executed with that data. The description argument will be a combination of the test description, the test data description, and the parameters. The parameters argument is a JSON string whose structure is entirely up to the user.
``` sql
create function my_schema.test_with_parameters(parameters jsonb, description text) returns setof text as $$
declare my_value integer := parameters->>0;
declare expected_result boolean := parameters->>1;
begin
    return query select pgtap.is(my_value > 0, expected_result, description);
end;$$ language plpgsql;
```
The above example is a test that checks if an integer is greater than zero. The parameters argument is (assumed to be) an array whose first element is the integer to compare to zero and whose second element is the expected result of that comparison.

### Adding and removing tests in the test plan

The functions `add_test` and `remove_test` add or remove tests in the test plan. The test functions do not necessarily have to exist in the database when `add_test` is called, they just have to exist before `execute_tests` is called. 

When a test is added to the test plan, an optional description and fixture can be specified as well. For example
``` sql
select add_test('my_schema', 'my_test_function', 'This is my test description.', 'my_app/my_component/my_group');
```
The fixture is written as a series of fixture names separated by '/' characters, similar to file paths. The above example defines three fixtures `my_app`, `my_app/my_component`, and `my_app/my_component/my_group`. Unless the fixtures are further configured, they only provide a way of organizing tests, which itself is useful for making it easy to execute only the set of tests contained within a fixture.

To remove a test from the test plan, just pass its schema and function name:
``` sql
select remove_test('my_schema', 'my_test_function');
```

A single test cannot be in multiple fixtures.

### Adding data for tests that take arguments

If a test takes arguments, then it will be executed once per test data that has been added for it. If no test data has been added for a test, then it will be skipped. Use the `add_test_data`, `remove_test_data`, and `remove_all_test_data` functions to add and remove data for a test.
``` sql
select
	add_test_data('my_schema', 'test1', $$select '[0, false]'$$, 'Try 0. Expect false.')
	, add_test_data('my_schema', 'test1', $$select '[1, true]'$$, 'Try 1. Expect true.')
	, add_test_data('my_schema', 'test1', $$select '[-1, false]'$$, 'Try -1. Expect false.')
;
```
The above query adds three data for the test named test1. Parameters are expressed as a statement that returns a single result that can be cast to the jsonb data type. In this example, the statements are selects that just return literal strings with valid json. The descriptions clarify the meaning of the parameters.

To remove a single test data, the exact parameters must be provided.
``` sql
select remove_test_data('my_schema', 'test1', $$select '[-1, false]'$$)
```
It is simpler to remove all the test data at once.
``` sql 
select remove_all_test_data('my_schema', 'test1')
```
Removing a test will also remove all of its test data implicitly.


### Configuring fixtures

A fixture can be configured before or after tests are added that use it. A fixture can be configured with any of the following:
-   A description
-   A startup script to run once before the fixture
-   A shutdown script to run once after the fixture
-   A setup script to run before each test and child fixture in the fixture
-   A teardown script to run after each test and child fixture in the fixture

``` sql
select configure_fixture(
	'my_app/my_component'
	, 'All tests for my component.'
	, $startup$create sequence my_sequence;$startup$
	, $shutdown$drop sequence my_sequence;$shutdown$
	, $setup$alter sequence my_sequence restart with 100;$setup$
	, $teardown$$teardown$
);
```
In the above example, a fixture is configured for manipulating a sequence that is used by tests in the my_app/my_component fixture. The sequence is created during startup and dropped during shutdown. Before each test in the fixture is executed, the sequence is restarted at 100 during the setup. No teardown is configured for this fixture.

It is worth mentioning that if a test throws an exception, the teardown and shutdown scripts will still be executed.

### Executing tests

Use the `execute_tests` function to execute the tests. If no (or all null) arguments are passed to `execute_tests`, then all of the tests and fixtures in the plan will be executed. Use the arguments to specify which tests and fixtures to execute. Suppose the following tests and fixtures are defined:
``` sql
select
    add_test('my_schema', 'test_a', 'description of a', 'my_app/my_component_1')
    , add_test('my_schema', 'test_b', 'description of b', 'my_app/my_component_1')
    , add_test('my_schema', 'test_c', 'description of c', 'my_app/my_component_2')
    , add_test('my_schema', 'test_d', 'description of d', 'my_app/my_component_2')
    , configure_fixture(
        fixturepath => 'my_app'
        , startup => $$create sequence my_sequence;$$
        , shutdown => $$drop sequence my_sequence;$$
    )
    , configure_fixture(
        fixturepath => 'my_app/my_component_1'
        , setup => $$alter sequence my_sequence restart with 1;$$
    )
    , configure_fixture(
        fixturepath => 'my_app/my_component_2'
        , setup => $$alter sequence my_sequence restart with 100;$$
    )
```
The following are the results of executing `execute_tests` with various arguments.
-   ``` sql
    select execute_tests()
    ```
    Since no arguments were provided, all of the fixtures and tests will be executed.
-   ``` sql
    select execute_tests(array['my_app/my_component_2'])
    ```
    The fixtures my_app and my_app/my_component_2 and the tests my_schema.test_c and my_schema.test_d. The parent fixture my_app must be executed, because its startup script needs to be executed before the tests.
-   ``` sql
    select execute_tests(null, 'my_schema', array['test_b'])
    ```
    The fixtures my_app and my_app/my_component1 and the test my_schema.test_b are executed. The parent fixtures must be executed, because their startup and setup scripts need to be executed before the test.
-   ``` sql
    select execute_tests(array['my_app/my_component_1'], 'my_schema', array['test_b'])
    ```
    Because test_b is contained in the fixture my_app/my_component_1, this is equivalent to
    ``` sql
    select execute_tests(array['my_app/my_component_1'])
    ```
    The fixtures my_app and my_app/my_component_1 and the tests my_schema.test_a and my_schema.test_b are executed.

After each test is executed, all changes that the test made to the database are rolled back.

## Complete example

``` sql
create or replace function example()
returns setof text
language plpgsql
as
$example$
begin
	-- Create the pgtap and pgtap_fixture extensions and add them to the search path

	create schema pgtap;
	create extension pgtap schema pgtap;
	create schema pgtap_fixture;
	create extension pgtap_fixture schema pgtap_fixture;
	create schema my_tests;
	execute 'set search_path to '||current_setting('search_path')||',pgtap,pgtap_fixture';
	
	-- Create some functions to test

	-- This sequence is used by the format_data function to number the data it outputs. 
	create sequence data_number as integer;
	-- This function verifies that a given string contains only numbers and is 8 characters long.
	create function is_id_valid(id text) returns boolean language sql as $$
		select id similar to '[0-9]+' and length(id) = 8;
	$$;
	-- This function takes a string like this: 		ThIs Is My DaTa
	-- and returns a string like this:				data14 : this is my data
	-- where the number 14 in this example is the current value of the data_number sequence.
	create function format_data(data text) returns text language sql as $$
		select 'data' ||nextval('data_number') || ' : ' || lower(data)
	$$;

	-- Create one test with some data and add it to a fixture.

	perform
		pgtap_fixture.add_test('my_tests', 'valid_id_content'
            , 'Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.'
            , 'all/is_id_valid')
		, pgtap_fixture.add_test_data('my_tests', 'valid_id_content'
            , $$select '[12345678, true]'$$, 'Try length 8. Expect true.')
		, pgtap_fixture.add_test_data('my_tests', 'valid_id_content'
            , $$select '[123456789, false]'$$, 'Try length 8. Expect false.')
		, pgtap_fixture.add_test_data('my_tests', 'valid_id_content'
            , $$select '[1234567, false]'$$, 'Try length 7. Expect false.')
		, pgtap_fixture.add_test_data('my_tests', 'valid_id_content'
            , $$select '["", false]'$$, 'Try length 0. Expect false.')
		, pgtap_fixture.add_test_data('my_tests', 'valid_id_content'
            , $$select '["abcdefgh", false]'$$, 'Try 8 letters. Expect false.')
		, pgtap_fixture.add_test_data('my_tests', 'valid_id_content'
            , $$select '["1abcdefg", false]'$$, 'Try 1 number and 7 letters. Expect false.')
		, pgtap_fixture.add_test_data('my_tests', 'valid_id_content'
            , $$select '["a1234567", false]'$$, 'Try 1 letter and 7 numbers. Expect false.')
	;
	create function my_tests.valid_id_content(parameters jsonb, description text)
	returns setof text language plpgsql as $$
	declare id text := parameters->>0;
	declare expected_result boolean := parameters->>1;
	begin
		return query select pgtap.is(is_id_valid(id), expected_result, description);
	end; $$;

    -- Create another test with some data, add it to a fixture, and configure that fixture's setup script.

	perform
		pgtap_fixture.add_test('my_tests', 'correctly_formatted_data'
            , 'Verifies that format_data correctly formats the data.'
            , 'all/format_data')
		, pgtap_fixture.add_test_data('my_tests', 'correctly_formatted_data'
            , $$select '["My Data", "data1 : my data"]'$$, 'Try length data with upper and lower case.')
		, pgtap_fixture.add_test_data('my_tests', 'correctly_formatted_data'
            , $$select '["MY DATA", "data1 : my data"]'$$, 'Try length data with upper case.')
		, pgtap_fixture.add_test_data('my_tests', 'correctly_formatted_data'
            , $$select '["my data", "data1 : my data"]'$$, 'Try length data with lower case.')
		, pgtap_fixture.configure_fixture(fixturepath => 'all/format_data'
            , description => 'fixture for format_data tests.'
            , setup => $setup$alter sequence data_number restart with 1;$setup$)
	;
	create function my_tests.correctly_formatted_data(parameters jsonb, description text)
	returns setof text language plpgsql as $$
	declare data text := parameters->>0;
	declare expected_result text := parameters->>1;
	begin
		return query select pgtap.is(format_data(data), expected_result, description);
	end; $$;

	-- Execute the tests
	
	return query select pgtap_fixture.execute_tests();

	-- Undo all changes
	drop function my_tests.correctly_formatted_data(parameters jsonb, description text);
	drop function my_tests.valid_id_content(parameters jsonb, description text);
	drop function format_data(data text);
	drop function is_id_valid(id text);
	drop sequence data_number;
	reset search_path;
	drop schema my_tests;
	drop extension pgtap_fixture;
	drop schema pgtap_fixture;
	drop extension pgtap;
	drop schema pgtap;
end;
$example$;
```

Executing `select example();` returns the following output

``` text
TAP Version 14
# Subtest: all 
    # Subtest: all/is_id_valid 
        # Subtest: my_tests.valid_id_content Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Subtest: my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try length 8. Expect true.
            # Test data: [12345678, true]
                ok 1 - Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
                # Test data description: Try length 8. Expect true.
                # Test data: [12345678, true]
                1..1
            ok 1 - my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try length 8. Expect true.
            # Test data: [12345678, true]
            # Subtest: my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try length 8. Expect false.
            # Test data: [123456789, false]
                ok 1 - Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
                # Test data description: Try length 8. Expect false.
                # Test data: [123456789, false]
                1..1
            ok 2 - my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try length 8. Expect false.
            # Test data: [123456789, false]
            # Subtest: my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try length 7. Expect false.
            # Test data: [1234567, false]
                ok 1 - Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
                # Test data description: Try length 7. Expect false.
                # Test data: [1234567, false]
                1..1
            ok 3 - my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try length 7. Expect false.
            # Test data: [1234567, false]
            # Subtest: my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try length 0. Expect false.
            # Test data: ["", false]
                ok 1 - Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
                # Test data description: Try length 0. Expect false.
                # Test data: ["", false]
                1..1
            ok 4 - my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try length 0. Expect false.
            # Test data: ["", false]
            # Subtest: my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try 8 letters. Expect false.
            # Test data: ["abcdefgh", false]
                ok 1 - Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
                # Test data description: Try 8 letters. Expect false.
                # Test data: ["abcdefgh", false]
                1..1
            ok 5 - my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try 8 letters. Expect false.
            # Test data: ["abcdefgh", false]
            # Subtest: my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try 1 number and 7 letters. Expect false.
            # Test data: ["1abcdefg", false]
                ok 1 - Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
                # Test data description: Try 1 number and 7 letters. Expect false.
                # Test data: ["1abcdefg", false]
                1..1
            ok 6 - my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try 1 number and 7 letters. Expect false.
            # Test data: ["1abcdefg", false]
            # Subtest: my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try 1 letter and 7 numbers. Expect false.
            # Test data: ["a1234567", false]
                ok 1 - Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
                # Test data description: Try 1 letter and 7 numbers. Expect false.
                # Test data: ["a1234567", false]
                1..1
            ok 7 - my_tests.valid_id_content Test description: Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
            # Test data description: Try 1 letter and 7 numbers. Expect false.
            # Test data: ["a1234567", false]
            1..7
        ok 1 - my_tests.valid_id_content Verifies that IDs are invalid if they are not 8 characters long or have anything but numbers.
        1..1
    ok 1 - all/is_id_valid 
    # Subtest: all/format_data fixture for format_data tests.
        # Subtest: my_tests.correctly_formatted_data Verifies that format_data correctly formats the data.
            # Subtest: my_tests.correctly_formatted_data Test description: Verifies that format_data correctly formats the data.
            # Test data description: Try length data with upper and lower case.
            # Test data: ["My Data", "data1 : my data"]
                ok 1 - Test description: Verifies that format_data correctly formats the data.
                # Test data description: Try length data with upper and lower case.
                # Test data: ["My Data", "data1 : my data"]
                1..1
            ok 1 - my_tests.correctly_formatted_data Test description: Verifies that format_data correctly formats the data.
            # Test data description: Try length data with upper and lower case.
            # Test data: ["My Data", "data1 : my data"]
            # Subtest: my_tests.correctly_formatted_data Test description: Verifies that format_data correctly formats the data.
            # Test data description: Try length data with upper case.
            # Test data: ["MY DATA", "data1 : my data"]
                ok 1 - Test description: Verifies that format_data correctly formats the data.
                # Test data description: Try length data with upper case.
                # Test data: ["MY DATA", "data1 : my data"]
                1..1
            ok 2 - my_tests.correctly_formatted_data Test description: Verifies that format_data correctly formats the data.
            # Test data description: Try length data with upper case.
            # Test data: ["MY DATA", "data1 : my data"]
            # Subtest: my_tests.correctly_formatted_data Test description: Verifies that format_data correctly formats the data.
            # Test data description: Try length data with lower case.
            # Test data: ["my data", "data1 : my data"]
                ok 1 - Test description: Verifies that format_data correctly formats the data.
                # Test data description: Try length data with lower case.
                # Test data: ["my data", "data1 : my data"]
                1..1
            ok 3 - my_tests.correctly_formatted_data Test description: Verifies that format_data correctly formats the data.
            # Test data description: Try length data with lower case.
            # Test data: ["my data", "data1 : my data"]
            1..3
        ok 1 - my_tests.correctly_formatted_data Verifies that format_data correctly formats the data.
        1..1
    ok 2 - all/format_data fixture for format_data tests.
    1..2
ok 1 - all 
1..1
```
