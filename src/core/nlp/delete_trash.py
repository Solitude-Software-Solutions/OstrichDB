#!/usr/bin/env python3
"""
Script to delete all files with specified extensions from a directory.
Extensions to delete: .so, .o, .dylib, .h
"""

import os
import sys
import argparse
from pathlib import Path


def delete_files_with_extensions(directory_path, extensions, dry_run=False, recursive=False):
    """
    Delete files with specified extensions from the given directory.

    Args:
        directory_path (str): Path to the directory to clean
        extensions (list): List of file extensions to delete
        dry_run (bool): If True, just list files that would be deleted without actually deleting
        recursive (bool): If True, search subdirectories too

    Returns:
        int: Number of files deleted
    """
    if not os.path.isdir(directory_path):
        print(f"Error: '{directory_path}' is not a valid directory")
        return 0

    deleted_count = 0

    try:
        if recursive:
            for root, _, files in os.walk(directory_path):
                for file in files:
                    file_path = os.path.join(root, file)
                    if any(file.endswith(ext) for ext in extensions):
                        if dry_run:
                            print(f"Would delete: {file_path}")
                        else:
                            os.remove(file_path)
                            print(f"Deleted: {file_path}")
                        deleted_count += 1
        else:
            for file in os.listdir(directory_path):
                file_path = os.path.join(directory_path, file)
                if os.path.isfile(file_path) and any(file.endswith(ext) for ext in extensions):
                    if dry_run:
                        print(f"Would delete: {file_path}")
                    else:
                        os.remove(file_path)
                        print(f"Deleted: {file_path}")
                    deleted_count += 1

    except Exception as e:
        print(f"Error: {e}")

    return deleted_count


def main():
    parser = argparse.ArgumentParser(
        description="Delete files with specified extensions from a directory"
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=".",
        help="Directory to clean (default: current directory)"
    )
    parser.add_argument(
        "-e", "--extensions",
        nargs="+",
        default=[".so", ".o", ".dylib", ".h"],
        help="File extensions to delete (default: .so .o .dylib .h)"
    )
    parser.add_argument(
        "-n", "--dry-run",
        action="store_true",
        help="Show what would be deleted without actually deleting"
    )
    parser.add_argument(
        "-r", "--recursive",
        action="store_true",
        help="Process subdirectories recursively"
    )

    args = parser.parse_args()

    # Ensure extensions start with a period
    extensions = [ext if ext.startswith(".") else f".{ext}" for ext in args.extensions]

    print(f"{'Dry run: ' if args.dry_run else ''}Deleting files with extensions {', '.join(extensions)} "
          f"from '{os.path.abspath(args.directory)}'{' (including subdirectories)' if args.recursive else ''}")

    if not args.dry_run:
        confirmation = input("Are you sure you want to proceed? (y/n): ")
        if confirmation.lower() != "y":
            print("Operation cancelled.")
            return

    count = delete_files_with_extensions(args.directory, extensions, args.dry_run, args.recursive)

    action = "Would delete" if args.dry_run else "Deleted"
    print(f"\n{action} {count} file(s)")


if __name__ == "__main__":
    main()