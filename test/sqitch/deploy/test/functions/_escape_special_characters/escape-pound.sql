-- Deploy dream-db-extension-tests:test/functions/_escape_special_characters/escape-pound to pg

BEGIN;

create function unit_test.test_func_escape__escape_pound()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When escaping special characters, the function shall replace each '#' character in the given string with '\#'.
$test_description$;
begin

    return query select tap.is(
        _escape_special_characters('One #pound'),
        'One \#pound',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: One pound in the middle of the string.$scenario$)
    );

    return query select tap.is(
        _escape_special_characters('One pound#'),
        'One pound\#',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: One pound at the end of the string.$scenario$)
    );

    return query select tap.is(
        _escape_special_characters('#One pound'),
        '\#One pound',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: One pound at the beginning of the string.$scenario$)
    );

    return query select tap.is(
        _escape_special_characters('#Multiple# #pounds#'),
        '\#Multiple\# \#pounds\#',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4: Multiple pounds.$scenario$)
    );

    return query select tap.is(
        _escape_special_characters('Multiple###pounds'),
        'Multiple\#\#\#pounds',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$5: Multiple adjacent pounds.$scenario$)
    );

end;
$$;

COMMIT;
