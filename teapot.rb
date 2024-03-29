
#
#  This file is part of the "Teapot" project, and is released under the MIT license.
#

teapot_version "3.0"

define_target "build-clang" do |target|
	target.depends :linker, public: true
	
	target.provides "Build/Clang" do
		default header_search_paths []
		
		define Rule, "compile.asm" do
			input :source_file, pattern: /\.(s)$/
			
			output :object_file
			
			apply do |parameters|
				input_root = parameters[:source_file].root
				mkpath File.dirname(parameters[:object_file])
				
				header_search_paths = environment[:header_search_paths].collect do |path|
					["-I", path.shortest_path(input_root)]
				end
				
				run!(environment[:cc],
					"-c", parameters[:source_file].relative_path,
					"-o", parameters[:object_file].shortest_path(input_root),
					*environment[:cflags].flatten,
					*header_search_paths.flatten,
					chdir: input_root
				)
			end
		end
		
		define Rule, "compile.c" do
			input :source_file, pattern: /\.(c|cc|m)$/
			
			input :dependencies, implicit: true do |arguments|
				depfile_path = arguments[:object_file].append('.d')
				
				if File.exist? depfile_path
					depfile = Build::Makefile.load_file(depfile_path)
					root = arguments[:source_file].root
					
					depfile.rules["dependencies"].collect{|path| Path.expand(path, root)}
				else
					[]
				end
			end
			
			output :object_file
			
			output :dependency_file, implicit: true do |arguments|
				arguments[:object_file].append(".d")
			end
			
			output :command_file, implicit: true do |arguments|
				arguments[:object_file].append(".compile_command.json")
			end
			
			apply do |parameters|
				input_root = parameters[:source_file].root
				mkpath File.dirname(parameters[:object_file])
				
				header_search_paths = environment[:header_search_paths].collect do |path|
					["-I", path.shortest_path(input_root)]
				end
				
				command = [
					environment[:cc],
					"-c", parameters[:source_file].relative_path,
					"-o", parameters[:object_file].shortest_path(input_root),
					"-MMD", "-MF", parameters[:dependency_file], "-MT", "dependencies",
					*environment[:cflags].flatten,
					*header_search_paths.flatten,
				]
				
				File.write(parameters[:command_file], JSON.pretty_generate({
					directory: input_root,
					arguments: command,
					file: parameters[:source_file].relative_path
				}))
				
				run!(*command, chdir: input_root)
			end
		end
		
		define Rule, "compile.cpp" do
			input :source_file, pattern: /\.(cpp|cxx|mm)$/
			
			input :dependencies, implicit: true do |arguments|
				depfile_path = arguments[:object_file].append('.d')
				
				if File.exist? depfile_path
					depfile = Build::Makefile.load_file(depfile_path)
					root = arguments[:source_file].root
					
					depfile.rules["dependencies"]&.collect{|path| Path.expand(path, root)}
				else
					[]
				end
			end
			
			output :object_file
			
			output :dependency_file, implicit: true do |arguments|
				arguments[:object_file].append(".d")
			end
			
			output :command_file, implicit: true do |arguments|
				arguments[:object_file].append(".compile_command.json")
			end
			
			apply do |parameters|
				input_root = parameters[:source_file].root
				mkpath File.dirname(parameters[:object_file])
				
				header_search_paths = environment[:header_search_paths].collect do |path|
					["-I", path.shortest_path(input_root)]
				end
				
				command = [
					environment[:cxx],
					"-c", parameters[:source_file].relative_path,
					"-o", parameters[:object_file].shortest_path(input_root),
					"-MMD", "-MF", parameters[:dependency_file].shortest_path(input_root), "-MT", "dependencies",
					*environment[:cxxflags].flatten,
					*header_search_paths.flatten
				]
				
				File.write(parameters[:command_file], JSON.pretty_generate({
					directory: input_root,
					arguments: command,
					file: parameters[:source_file].relative_path
				}))
				
				run!(*command, chdir: input_root)
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
end

define_target "build-clang-language" do |target|
	target.depends "Build/Clang", public: true
	
	target.provides "Language/C99" do
		cflags %W{-std=c99}
		ld environment[:cc]
	end
	
	target.provides "Language/C++11" do
		cxxflags %W{-std=c++11 -pthread}
		linkflags %W{-pthread}
		ld environment[:cxx]
	end
	
	target.provides "Language/C++14" do
		cxxflags %W{-std=c++14 -pthread}
		linkflags %W{-pthread}
		ld environment[:cxx]
	end
	
	target.provides "Language/C++17" do
		cxxflags %W{-std=c++17 -pthread}
		linkflags %W{-pthread}
		ld environment[:cxx]
	end
	
	target.provides "Language/C++20" do
		cxxflags %W{-std=c++20 -pthread}
		linkflags %W{-pthread}
		ld environment[:cxx]
	end
end
