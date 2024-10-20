#!/bin/bash

# Constants
CHUNK_SIZE=$((100 * 1024 * 1024))  # 100 MB in bytes

# Initialize variables for tracking
TOTAL_SIZE=0
CHUNK_COUNT=0
PROGRESS_BAR_WIDTH=50

# Function to display progress bar
display_progress() {
    local progress=$((CHUNK_COUNT * 100 / TOTAL_CHUNKS))
    local filled=$((progress * PROGRESS_BAR_WIDTH / 100))
    printf "\rProgress: [%-${PROGRESS_BAR_WIDTH}s] %d%%" "$(printf "%0.s=" $(seq 1 $filled))" "$progress"
}

# Function to add files in chunks
add_files_in_chunks() {
    local current_chunk_size=0
    local files=()

    # Collect all files in the repository
    while IFS= read -r -d '' file; do
        # Get file size
        local file_size=$(stat -f%z "$file")

        # Check if adding this file exceeds the chunk size
        if (( current_chunk_size + file_size > CHUNK_SIZE )); then
            # Commit current chunk to the main branch
            git add "${files[@]}"
            git commit -m "Committing chunk $CHUNK_COUNT to main"
            git push origin main

            # Reset for the next chunk
            current_chunk_size=0
            files=()
            CHUNK_COUNT=$((CHUNK_COUNT + 1))
            display_progress
        fi

        # Add file to the current chunk
        files+=("$file")
        current_chunk_size=$((current_chunk_size + file_size))
    done < <(find . -type f -print0)

    # Commit any remaining files in the last chunk
    if (( ${#files[@]} > 0 )); then
        git add "${files[@]}"
        git commit -m "Committing chunk $CHUNK_COUNT to main"
        git push origin main
    fi
}

# Count the total number of chunks needed
TOTAL_FILES=$(find . -type f | wc -l)
TOTAL_CHUNKS=$(( (TOTAL_FILES + (CHUNK_SIZE / 1024) - 1) / (CHUNK_SIZE / 1024) ))  # Rough estimation of chunks

# Add files in chunks directly to the main branch
add_files_in_chunks

# Final commit for all changes (if any remaining)
git checkout main  # Ensure we're on the main branch
git add -A  # Stage all changes again
git commit -m "Final commit of all changes"
git push origin main  # Push the final commit

echo -e "\nAll chunks have been committed and pushed directly to the main branch!"
