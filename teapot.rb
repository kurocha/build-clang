
#
#  This file is part of the "Teapot" project, and is released under the MIT license.
#

teapot_version "1.0.0"

define_target "build-clang" do |target|
	target.depends :linker
	
	target.provides "Build/Clang" do
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
				
				run!(environment[:cc],
					"-c", parameters[:source_file].relative_path,
					"-o", parameters[:object_file].shortest_path(input_root),
					"-MMD", "-MF", parameters[:dependency_file], "-MT", "dependencies",
					*environment[:cflags].flatten,
					"-I", (environment[:install_prefix] + "include").shortest_path(input_root),
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
				
				run!(environment[:cxx],
					"-c", parameters[:source_file].relative_path,
					"-o", parameters[:object_file].shortest_path(input_root),
					"-MMD", "-MF", parameters[:dependency_file].shortest_path(input_root), "-MT", "dependencies",
					*environment[:cxxflags].flatten,
					"-I", (environment[:install_prefix] + "include").shortest_path(input_root),
					chdir: input_root
				)
			end
		end
		
		# This rule compiles source files and links the resultant object files into a library, either static or dynamic depending on the file extension for the given platform.
		define Rule, "build.native-library" do
			input :source_files 
			output :library_file
			
			apply do |parameters|
				build_prefix = environment[:build_prefix] + environment.checksum
				
				object_files = parameters[:source_files].collect do |file|
					object_file = build_prefix / (file.relative_path + '.o')
					
					compile source_file: file, object_file: object_file
				end
				
				link :object_files => object_files, :library_file => parameters[:library_file]
			end
		end
		
		# This rule compiles source files and links the resultant object files into an executable.
		define Rule, "build.native-executable" do
			input :source_files
			output :executable_file
			
			apply do |parameters|
				build_prefix = environment[:build_prefix] + environment.checksum
				
				object_files = parameters[:source_files].collect do |file|
					object_file = build_prefix / (file.relative_path + '.o')
					
					compile source_file: file, object_file: object_file
				end
				
				link :object_files => object_files, :executable_file => parameters[:executable_file]
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
