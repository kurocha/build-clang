
#
#  This file is part of the "Teapot" project, and is released under the MIT license.
#

teapot_version "3.0"

define_target "build-clang" do |target|
	target.depends :linker, public: true
	
	target.provides "Build/Clang" do
		default header_search_paths []
		
		define Rule, "compile.c" do
			input :source_file, pattern: /\.(s|c|cc|m)$/
			
			input :dependencies, implicit: true do |arguments|
				depfile_path = arguments[:object_file].append('.d')
				
				if File.exist? depfile_path
					depfile = Build::Makefile.load_file(depfile_path)
					root = arguments[:source_file].root
					
					depfile.rules["dependencies"].collect{|relative_path| Path.join(root, relative_path)}
				else
					[]
				end
			end
			
			output :object_file
			
			output :dependency_file, implicit: true do |arguments|
				arguments[:object_file].append(".d")
			end
			
			apply do |parameters|
				input_root = parameters[:source_file].root
				mkpath File.dirname(parameters[:object_file])
				
				header_search_paths = environment[:header_search_paths].collect do |path|
					["-I", path.shortest_path(input_root)]
				end
				
				run!(environment[:cc],
					"-c", parameters[:source_file].relative_path,
					"-o", parameters[:object_file].shortest_path(input_root),
					"-MMD", "-MF", parameters[:dependency_file], "-MT", "dependencies",
					*environment[:cflags].flatten,
					*header_search_paths.flatten,
					chdir: input_root
				)
			end
		end
		
		define Rule, "compile.cpp" do
			input :source_file, pattern: /\.(cpp|cxx|mm)$/
			
			input :dependencies, implicit: true do |arguments|
				depfile_path = arguments[:object_file].append('.d')
				
				if File.exist? depfile_path
					depfile = Build::Makefile.load_file(depfile_path)
					root = arguments[:source_file].root
					
					depfile.rules["dependencies"].collect{|relative_path| Path.join(root, relative_path)}
				else
					[]
				end
			end
			
			output :object_file
			
			output :dependency_file, implicit: true do |arguments|
				arguments[:object_file].append(".d")
			end
			
			apply do |parameters|
				input_root = parameters[:source_file].root
				mkpath File.dirname(parameters[:object_file])
				
				header_search_paths = environment[:header_search_paths].collect do |path|
					["-I", path.shortest_path(input_root)]
				end
				
				run!(environment[:cxx],
					"-c", parameters[:source_file].relative_path,
					"-o", parameters[:object_file].shortest_path(input_root),
					"-MMD", "-MF", parameters[:dependency_file].shortest_path(input_root), "-MT", "dependencies",
					*environment[:cxxflags].flatten,
					*header_search_paths.flatten,
					chdir: input_root
				)
			end
		end
		
		# This rule compiles source files and links the resultant object files into a library, either static or dynamic depending on the file extension for the given platform.
		define Rule, "build.native-library" do
			input :source_files
			parameter :build_prefix
			output :library_file
			
			apply do |parameters|
				build_prefix = parameters[:build_prefix]
				
				object_files = parameters[:source_files].collect do |file|
					object_file = build_prefix / (file.relative_path + '.o')
					
					compile source_file: file, object_file: object_file
				end
				
				link object_files: object_files, library_file: parameters[:library_file]
			end
		end
		
		# This rule compiles source files and links the resultant object files into an executable.
		define Rule, "build.native-executable" do
			input :source_files
			parameter :build_prefix
			output :executable_file
			
			apply do |parameters|
				build_prefix = parameters[:build_prefix]
				
				object_files = parameters[:source_files].collect do |file|
					object_file = build_prefix / (file.relative_path + '.o')
					
					compile source_file: file, object_file: object_file
				end
				
				link object_files: object_files, executable_file: parameters[:executable_file]
			end
		end
	end
	
	target.provides "Language/C99" do
		cflags %W{-std=c99}
	end
	
	target.provides "Language/C++11" do
		cxxflags %W{-std=c++11 -pthread}
		linkflags %W{-pthread}
	end
	
	target.provides "Language/C++14" do
		cxxflags %W{-std=c++14 -pthread}
		linkflags %W{-pthread}
	end
end
