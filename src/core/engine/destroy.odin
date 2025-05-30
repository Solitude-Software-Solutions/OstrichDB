package engine

import "../../utils"
import "../const"
import "../types"
import "./security"
import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-2025 Marshall A Burns and Solitude Software Solutions LLC
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            This file holds the logic for the DESTROY command, which
            allows users to delete the entire OstrichDB instance.
*********************************************************/

//Deletes the entire executiable, databases, history files, user files, and cache files.
DESTROY_EVERYTHING :: proc() {
	using const

	if types.user.role.Value != "admin" {
		fmt.printfln("You must be an admin to destroy OstrichDB.")
		return
	}

	fmt.printfln(
		"%s%sWARNING%s You are about to destroy OstrichDB. This will delete:\n- All databases\n- All user files\n- All cache files\n- All history files\n- The OstrichDB executable\n\nThis operation is irreversible. To confirm, type %sconfirm%s. To cancel, type %scancel%s.",
		utils.RED,
		utils.BOLD_UNDERLINE,
		utils.RESET,
		utils.BOLD,
		utils.RESET,
		utils.BOLD,
		utils.RESET,
	)

	i := utils.get_input(false)
	input := string(strings.to_upper(i))
	switch (input) {
	case CONFIRM:
		fmt.println("Please enter your password to confirm the destruction of OstrichDB.")
		j := utils.get_input(true)
		password := string(j)
		validatedPassword := security.VALIDATE_USER_PASSWORD(password)
		switch (validatedPassword) {
		case true:
			fmt.printfln("%sDestroying OstrichDB...%s", utils.RED, utils.RESET)
			break
		case false:
			fmt.printfln("Invalid password. Operation cancelled.")
			return
		}

		break
	case CANCEL:
		fmt.println("Destroy operation cancelled.")
		return
	case:
		fmt.println("Invalid input. Destroy operation cancelled.")
		return
	}


	dirs := []string {
		const.PRIVATE_PATH,
		const.PUBLIC_PATH,
		const.STANDARD_COLLECTION_PATH,
		const.LOG_DIR_PATH,
		"./tmp/",
	}
	for dir in dirs {
		os.remove(dir)
	}
	// //remove files in sub-directories
	// for dir in dirs {
	// 	dir_handle, err := os.open(dir)
	// 	if err != 0 {
	// 		utils.log_err(fmt.tprintf("Failed to open directory %s", dir), #procedure)
	// 		continue
	// 	}
	// 	defer os.close(dir_handle)

	// 	files, read_err := os.read_dir(dir_handle, -1)
	// 	if read_err != 0 {
	// 		utils.log_err(fmt.tprintf("Failed to read directory %s", dir), #procedure)
	// 		continue
	// 	}

	// 	for file in files {
	// 		file_path := fmt.tprintf("%s%s", dir, file.name)
	// 		err := os.remove(file_path)
	// 		if err != 0 {
	// 			utils.log_err(fmt.tprintf("Failed to remove file %s", file_path), #procedure)
	// 		}
	// 	}
	// }

	//remove files in binary dir
	files := []string{"./main.bin"}

	for file in files {
		err := os.remove(file)
		if err != 0 {
			fmt.printfln("%sFailed to remove %s%s", utils.RED, file, utils.RESET)
			utils.log_err(fmt.tprintf("Failed to remove %s during destruction", file), #procedure)
		}
	}

	// //remove the empty dirs
	for dir in dirs {
		err := os.remove(dir)
		if err != 0 {
			utils.log_err(fmt.tprintf("Failed to remove directory %s", dir), #procedure)
		}
	}

	fmt.printfln("%sOstrichDB has been destroyed.%s", utils.GREEN, utils.RESET)
	fmt.printfln("%sRebuilding OstrichDB...%s", utils.GREEN, utils.RESET)

	REBUILD_OSTRICHDB()
}
