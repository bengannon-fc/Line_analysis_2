# Line analysis 2.0
This line analysis workflow is designed to extract raster data at fixed intervals along lines to generate line level summary metrics. It was developed for wildland fire management to rate potential containment lines on multiple dimensions of opportunity, difficulty, and safety. The core sampling, extraction, and summary workflow may have other applications in natural resources management.

**Major changes from earlier versions**
•	The spatial input is simplified to a single polyline shapefile. The shapefile must have a spatial projection defined. Features should be singlepart; if not, they will be converted to singlepart in the script. Instead of representing multiple strategies in different shapefiles, users are encouraged to attribute their lines with a “Strategy” text attribute field using P-A-C-E terms, Direct/Indirect, or similar classification scheme.
•	Raster inputs can now have different extents, cell sizes, cell alignments, and projections.
•	Raster inputs are loaded one at a time to reduce the memory limitation errors.
•	There is now an optional workflow for creating barplots to contrast strategies if lines are attributed with a text “Strategy” field.
