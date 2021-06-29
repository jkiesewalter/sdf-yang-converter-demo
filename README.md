# sdf-yang-converter-demo
A web application to be used with the SDF YANG converter from https://github.com/jkiesewalter/sdf-yang-converter.

Install required Ruby Gems with `bundle install`. Run the application with `thin -R config.ru -a 127.0.0.1 -p 8080 start` to find it at `http://localhost:8080/`.
The directory from which the application is run must contain the converter binary as well as the files `sdf-validation.cddl` and `sdf_extension.yang` from https://github.com/jkiesewalter/sdf-yang-converter.
