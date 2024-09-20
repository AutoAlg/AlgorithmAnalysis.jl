# Julia script to write "A B C D" to a file directly
output_file_path = "S:\\Research Material\\CSE\\MU\\Project\\5Testing\\output.txt"

# Open the file and write the string "A B C D"
open(output_file_path, "w") do f
    write(f, "A B C D");  # Directly write the string to the file
end
