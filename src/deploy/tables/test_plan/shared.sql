-- Deploy dream-db-extension:create-test-plan-table to pg

BEGIN;
--#region exclude_transaction

create table test_plan
(
    id integer not null unique references test on delete cascade,
    ok boolean
);

comment on table test_plan is
    'Contains the tests that are planned.';
comment on column test_plan.id is
    'The ID of the test that is planned';
comment on column test_plan.ok is
    'The status of the planned test. True = ok, false = not ok, null = test has not been executed.';

--#endregion exclude_transaction
COMMIT;
