-- Deploy dream-db-extension:functions/_get_fixture_by_path_and_root/create to pg

BEGIN;
--#region exclude_transaction

create function _get_fixture_by_path_and_root(
    fixturePath text,
    root integer,
    createMissingFixtures boolean default false
)
returns integer
language plpgsql
as
$$
declare path_pattern text := $pattern$(^[^/]+)/?(.+$)?$pattern$;
declare remaining_fixture_path text;
declare fixture_id integer;
begin

    if not _is_fixture_path_valid(fixturePath) then
        raise 'The fixture path "%" is invalid.', fixturePath;
    end if;

    if fixturePath is null then
        raise 'The fixture path is null.';
    end if;

    -- For each node of the fixture path (the parts between the slashes), find the fixture whose name matches
    -- the node name and whose parent fixture ID matches the ID of the fixture that corresponded with the
    -- previous node name. The last fixture is the one that should be returned by this function.
    with recursive path_node(remaining_path, root_id, depth) as (
        values(fixturePath, root, 1)
        union
        select
            path_part[2],   -- The second match from the regexp is the remaining portion of the fixture path.
            fixture.id,
            path_node.depth + 1
        from fixture
		cross join path_node
        -- Get the name of the fixture before the first slash in the fixture path and the remaining path after
        -- the first slash in the fixture path. These strings will become the first and second elements in the
        -- path_part array.
		cross join regexp_matches(path_node.remaining_path, path_pattern) "path_part"
        where
            fixture.name = path_part[1] -- The first match from the regexp is the fixture name
            and (
                fixture.parent_fixture_id = path_node.root_id
                or (
                    fixture.parent_fixture_id is null
                    and path_node.root_id is null
                )
            )
    )
	select -- Only select the last record, which is the record with the highest depth value
		last_value(path_node.remaining_path) over wnd,
		last_value(path_node.root_id) over wnd
	from path_node
    window wnd as (order by depth desc)
	limit 1
	into remaining_fixture_path, fixture_id
	;

    if remaining_fixture_path is not null then
        -- Some fixtures in the path don't exist.
        if createMissingFixtures then
            -- Create missing fixtures in the fixture path.
            while createMissingFixtures
            loop
                with next_fixture(name, remaining_path) as (
                    -- Get the name of the next fixture to create from the front of the fixture path.
                    select
                        path_part[1],
                        path_part[2]
                    from regexp_matches(remaining_fixture_path, path_pattern) "path_part"
                ),
                new_fixture(id) as (
                    -- Create a fixture with that name, using the ID of the previous fixture as the parent fixture.
                    insert into fixture ("name", "parent_fixture_id")
                    select next_fixture.name, fixture_id
                    from next_fixture
                    returning id
                )
                -- Update the variables for the next loop iteration.
                select
                    new_fixture.id,
                    next_fixture.remaining_path,
                    next_fixture.remaining_path is not null
                into
                    fixture_id,
                    remaining_fixture_path,
                    createMissingFixtures
                from next_fixture, new_fixture
                ;
            end loop;
        else
            -- Don't create the missing fixtures in the fixture path. Return null to indicate that a fixture
            -- with this path does not exist.
            return null;
        end if;
    end if;

    return fixture_id;

end;
$$;

comment on function _get_fixture_by_path_and_root(
    fixturePath text,
    root integer,
    createMissingFixtures boolean
) is
    $$Returns the id of a fixture in the fixture table at the given fixture path. Use NULL for the root argument when fixturePath is not a partial path. If fixturePath is a partial path, then use the id of the fixture that fixturePath is relative to.
    If no fixture exists with the given path, then this function returns NULL, unless createMissingFixtures is TRUE. If createMissingFixtures is TRUE, then all fixtures in the path that don't exist will be created.
    Arguments:
        fixturePath: The path of the fixture. A path is a series of fixture names separated by slashes '/'.
        root: The id of the fixture in the fixture table that fixturePath is relative to. Use NULL if fixturePath is not a partial path.
        createMissingFixtures: If TRUE, then if any fixtures in fixturePath don't exist, then they will be created.$$;

--#endregion exclude_transaction
COMMIT;
