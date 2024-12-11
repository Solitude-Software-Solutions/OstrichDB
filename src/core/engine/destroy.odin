package engine
import "../../utils"
import "../const"
import "core:fmt"
import "core:os"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//Deletes the entire executiable, databases, history files, user files, and cache files.
OST_DESTROY :: proc() {
	using const
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

	i := utils.get_input()
	input := string(strings.to_upper(i))
	switch (input) {
	case CONFIRM:
		fmt.printfln("%sDestroying OstrichDB...%s", utils.RED, utils.RESET)
		break
	case CANCEL:
		fmt.println("Destroy operation cancelled.")
		return
	case:
		fmt.println("Invalid input. Destroy operation cancelled.")
		return
	}

	os.remove("./backups")
	os.remove("./collections")
	os.remove("./logs")
	os.remove("./quarantine")
	os.remove("./secure")
	os.remove("./tmp")
	os.remove("./cluster_id_cache")
	os.remove("./history.ost")
	os.remove("./main.bin")
	os.remove("./ostrich.config")

	fmt.printfln("%sOstrichDB has been destroyed.\n Rebuilding...%s", utils.GREEN, utils.RESET)
	OST_REBUILD()


}
