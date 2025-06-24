-- Deploy dream-db-extension-tests:table-fixture-insert-name-not-zero-length to pg

BEGIN;

create function unit_test.test_table_fixture_insert__name_not_zero_length()
returns setof text
language plpgsql
as
$$
declare test_description text :=$description$
If a record is added to the fixture table, and if that record's name's length is zero characters, then the
database shall throw an exception.
$description$;
begin
    return query select tap.throws_ok
    (
        $throws$insert into fixture ("name") values ('');$throws$,
        null,
        test_description
    )
    ;
end;
$$;

COMMIT;
