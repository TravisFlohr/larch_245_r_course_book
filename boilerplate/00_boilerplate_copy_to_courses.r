# Define absolute paths
source_dir <- "/Volumes/Pro/Library/Tools/teaching_boilerplate/teaching_boilerplate"
target_base <- "/Users/travis_flohr/Library/CloudStorage/OneDrive-SharedLibraries-ThePennsylvaniaStateUniversity/T-Ecology_and_Plants_II-2026_Fall - Documents/larch_245_r_course_book/"
target_dir <- file.path(target_base, "boilerplate")

# Function to check for overwrite permission
check_overwrite <- function() {
  cat("\nWarning: The 'boilerplate' folder already exists and contains files.\n")
  user_input <- readline(prompt = "Do you want to overwrite existing files? (y/n): ")
  return(tolower(user_input) == "y")
}

# Find all .qmd and .R files in the source directory (case-insensitive)
target_files <- list.files(
  path = source_dir, 
  pattern = "\\.(qmd|[rR])$", 
  full.names = TRUE
)

if (length(target_files) == 0) {
  stop("No .qmd or .R files found in the source directory.")
}

# Flag to control the copy process
proceed_with_copy <- TRUE

# Check if target folder exists and has files
if (dir.exists(target_dir)) {
  existing_files <- list.files(target_dir)
  if (length(existing_files) > 0) {
    proceed_with_copy <- check_overwrite()
  }
} else {
  # Create the folder if it does not exist
  dir.create(target_dir, recursive = TRUE)
}

# Perform the copy if permitted
if (proceed_with_copy) {
  success <- file.copy(from = target_files, to = target_dir, overwrite = TRUE)
  if (all(success)) {
    cat("\nSuccess! All .qmd and .R files copied to:", target_dir, "\n")
  } else {
    cat("\nError: Some files failed to copy.\n")
  }
} else {
  cat("\nOperation cancelled. No files were overwritten.\n")
}
