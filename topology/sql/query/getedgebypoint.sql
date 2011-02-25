-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 
-- PostGIS - Spatial Types for PostgreSQL
-- http://postgis.refractions.net
--
-- Copyright (C) 2011 Andrea Peri
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

--{
--
-- Andrea Peri (19 Jan 2011) creation
-- Andrea Peri (14 Feb 2011) minor issues
--
-- GetEdgeByPoint(atopology, point, tol)
--
-- Retrieve an Edge ID given a POINT and a tolerance
-- tolerance = 0 mean exactly intersection
--
-- Returns return the integer ID if there is an edge on the Point.
--
-- When the Point is even a Node it raise an exception. 
-- This case is testable with the GetNodeByPoint(atopology, apoint, tol)
--
-- If there isn't any edge in the Point, GetEdgeByPoint return 0.
--
-- if near the point there are two or more edges it throw an exception.
--
CREATE OR REPLACE FUNCTION topology.GetEdgeByPoint(atopology varchar, apoint geometry, tol1 float8)
	RETURNS int
AS
$$
DECLARE
	sql text;
	idedge int;
BEGIN
	--
	-- Atopology and apoint are required
	-- 
	IF atopology IS NULL OR apoint IS NULL THEN
		RAISE EXCEPTION 'Invalid null argument';
	END IF;

	--
	-- Apoint must be a point
	--
	IF substring(geometrytype(apoint), 1, 5) != 'POINT'
	THEN
		RAISE EXCEPTION 'Node geometry must be a point';
	END IF;

	--
	-- Tolerance must be >= 0
	--
	IF tol1 < 0
	THEN
		RAISE EXCEPTION 'Tolerance must be >=0';
	END IF;


    if tol1 = 0 then
    	sql := 'SELECT a.edge_id FROM ' 
        || quote_ident(atopology) 
        || '.edge_data as a WHERE '
        || '(a.geom && ' || quote_literal(apoint::text)||'::geometry) '
        || ' AND (ST_Intersects(a.geom,' || quote_literal(apoint::text)||'::geometry) );';
    else
    	sql := 'SELECT a.edge_id FROM ' 
        || quote_ident(atopology) 
        || '.edge_data as a WHERE '
        || '(ST_DWithin(a.geom,' || quote_literal(apoint::text)||'::geometry,' || tol1::text || ') );';
    end if;

    BEGIN
    EXECUTE sql INTO STRICT idedge;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            idedge = 0;
        WHEN TOO_MANY_ROWS THEN
            RAISE EXCEPTION 'Two or more edges founded';
    END;

	RETURN idedge;
	
END
$$
LANGUAGE 'plpgsql' STRICT;
--} GetEdgeByPoint
