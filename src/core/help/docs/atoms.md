<table>
  <tr>
    <th>Token</th>
    <th>Class</th>
    <th>Type</th>
    <th>Definition</th>
  </tr>

  <tr>
    <td>
      VERSION
    </td>
    <td>
      Action
    </td>
    <td>
      Single
    </td>
    <td>
      Fetches the current installed version of OstrichDB
    </td>
  </tr>

  <tr>
    <td>
      HELP
    </td>
    <td>
      Action
    </td>
    <td>
      Single or Multi
    </td>
    <td>
      Displays helpful information about OstrichDB
    </td>
  </tr>

  <tr>
    <td>
      EXIT
    </td>
    <td>
      Action
    </td>
    <td>
      Single
    </td>
    <td>
      Safely exits OstrichDB
    </td>
  </tr>

  <tr>
    <td>
      LOGOUT
    </td>
    <td>
      Action
    </td>
    <td>
      Single
    </td>
    <td>
      Logs out the current user WITHOUT closing OstrichDB
    </td>
  </tr>

  <tr>
    <td>
      NEW
    </td>
    <td>
      Action
    </td>
    <td>
      Multi
    </td>
    <td>
      Creates a new collection, cluster, or record
    </td>
  </tr>

  <tr>
    <td>
      ERASE
    </td>
    <td>
      Action
    </td>
    <td>
      Multi
    </td>
    <td>
      Deletes a collection, cluster, or record
    </td>
  </tr>

  <tr>
    <td>
      RENAME
    </td>
    <td>
      Action
    </td>
    <td>
      Multi
    </td>
    <td>
      Renames a collection, cluster, or record
    </td>
  </tr>

  <tr>
    <td>
      BACKUP
    </td>
    <td>
      Action
    </td>
    <td>
      Multi
    </td>
    <td>
      Creates a backup of a collection
    </td>
  </tr>

  <tr>
    <td>
      FETCH
    </td>
    <td>
      Action
    </td>
    <td>
      Multi
    </td>
    <td>
      Fetches all data of the specified collection, cluster, or record
    </td>
  </tr>

  <tr>
    <td>
      FOCUS
    </td>
    <td>
      Action
    </td>
    <td>
      Multi
    </td>
    <td>
      Sets the current context to the specified collection, cluster, or record
    </td>
  </tr>

  <tr>
    <td>
      UNFOCUS
    </td>
    <td>
      Action
    </td>
    <td>
      Single
    </td>
    <td>
      Unsets the current context if any
    </td>
  </tr>

  <tr>
    <td>
      CLEAR
    </td>
    <td>
      Action
    </td>
    <td>
      Single
    </td>
    <td>
      Clears the screen of clutter
    </td>

  <tr>
    <td>
      COLLECTION
    </td>
    <td>
      Target
    </td>
    <td>
    </td>
    <td>
      Specifies that the target is a collection
    </td>
  </tr>

  <tr>
    <td>
      CLUSTER
    </td>
    <td>
      Target
    </td>
    <td>
    </td>
    <td>
      Specifies that the target is a cluster
    </td>
  </tr>

  <tr>
    <td>
      RECORD
    </td>
    <td>
      Target
    </td>
    <td>
    </td>
    <td>
      Specifies that the target is a record
    </td>
  </tr>

  <tr>
    <td>
      TO
    </td>
    <td>
      Modifier
    </td>
    <td>
    </td>
    <td>
      Used with the RENAME action to specify the new name of the target
    </td>
  </tr>

  <tr>
    <td>
      WITHIN
    </td>
    <td>
      Scope Modifier
    </td>
    <td>
    </td>
    <td>
      Specifies the scope of the target in which the action should be performed
    </td>
  </tr>
</table>
