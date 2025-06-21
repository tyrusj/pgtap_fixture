-- Deploy dream-db-extension:create-fixture-plan-table to pg

BEGIN;
--#region exclude_transaction

create table fixture_plan
(
    id integer not null unique references fixture on delete cascade,
    ok boolean
);

comment on table fixture_plan is
    'Contains the fixtures that are planned.';
comment on column fixture_plan.id is
    'The ID of the fixture that is planned';
comment on column fixture_plan.ok is
    'The status of the planned fixture. True = ok, false = not ok, null = fixture has not been executed.';

--#endregion exclude_transaction
COMMIT;
