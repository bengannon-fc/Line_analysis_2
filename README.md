# Line analysis 2.0
This line analysis workflow is designed to extract raster data at fixed intervals along lines to generate line level summary metrics. It was developed for wildland fire management to rate potential containment lines on multiple dimensions of opportunity, difficulty, and safety. The core sampling, extraction, and summary workflow may have other applications in natural resources management.

**Major changes from earlier versions**

1) The spatial input is simplified to a single polyline shapefile. The shapefile must have a spatial projection defined. Features should be singlepart; if not, they will be converted to singlepart in the script. Instead of representing multiple strategies in different shapefiles, users are encouraged to attribute their lines with a “Strategy” text attribute field using P-A-C-E terms, Direct/Indirect, or similar classification scheme.
2) Raster inputs can now have different extents, cell sizes, cell alignments, and projections.
3) Raster inputs are loaded one at a time to reduce the memory limitation errors.
4) There is now an optional workflow for creating barplots to contrast strategies if lines are attributed with a text “Strategy” field.

**Sampling framework**

The sampling scheme was designed with two uses in mind: 1) points with local attributes for visualizing differences in condition along lines and 2) polylines with summary attributes for strategic planning. First, regular sample points are generated along each polyline with the spacing set by the user (100-m is recommended). Then, input data values are extracted within a sample area around each point based on the radius provided by the user (60-m is recommended). Each polyline and associated sample points are assigned matching line identifier (LID) attributes for relating their data tables. The polyline summary statistics are then calculated from the points associated with each line. The outputs include shapefiles of both the sample points and summary line features.

![image](https://github.com/bengannon-fc/Line_analysis/assets/81584637/f2f95ab4-6610-4f74-9378-c8f072675a85)
