This file is intended to give a quick overview of important and potentially non-backward-compatible changes. Please refer to the git log for a full list of changes.

# August, 2017
 * New command “Run Failed Examples in Selected Files” (<kbd>⇧⌘R</kbd>, same as “Run Single Example”).
 * New command “Run Single Example in Terminal” (<kbd>⇧⌘R</kbd>, same as “Run Single Example”).
 
# February, 2017
 * Support for RSpec 2 has been dropped from master. Please use the branch `rspec2` instead.
 * The shortcut for “Run Again” has been changed from <kbd>⌥⌘R</kbd> to <kbd>⌃⌥⌘R</kbd> so it no longer overrides  TextMate’s shortcut for Edit → Find → Find Behaviour → Regular Expression.
 
# August, 2014
 
 * There is a new “Run Again” command, bound to <kbd>⌥⌘R</kbd>. (“Run Last Example File” is still available but has no longer a shortcut by default.)
 * The shortcut for “Run Examples in selected files/directories” has changed to <kbd>⌥⇧⌘R</kbd>.
 * “Run Examples in selected files/directories” now runs all examples in `spec/` if nothing is selected (hint: use <kbd>⌘⇧A</kbd> to quickly deselect all files and directories).
 * __Drop support for TextMate 1 and RSpec 1__. Please use the legacy version from the branch “rspec1-textmate1” if necessary.
 * Change shortcut for __“Alternate File”__ from <kbd>⌃⇧↓</kbd> to <kbd>⌃⌥⇧↓</kbd>. You can get back the old shortcut by opening the bundle editor (“Bundles → Edit Bundles”), navigating to “RSpec → Menu Actions → Alternate File” and setting “Key Equivalent” accordingly. See [#57](https://github.com/rspec/rspec-tmbundle/issues/57) for the reason of this change.