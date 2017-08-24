#!/bin/zsh

# Keyboard setup: The following is based on the same code, we wrote for
# debian's setup. It ensures the terminal is in the right mode, when zle is
# active, so the values from $terminfo are valid. Therefore, this setup should
# work on all systems, that have support for `terminfo'. It also requires the
# zsh in use to have the `zsh/terminfo' module built.
#
# If you are customising your `zle-line-init()' or `zle-line-finish()'
# functions, make sure you call the following utility functions in there:
#
#     - zle-line-init():      zle-smkx
#     - zle-line-finish():    zle-rmkx


bindkey -v # Link viins to main.
# bindkey -e # Link emacs to main.

# Hundreths of a second (1=10ms).  Default is 40 (400ms).
KEYTIMEOUT=10

function widget-autoload-register() {
  emulate -L zsh
  local widget=$1
  autoload $widget && zle -N $widget
}

# Autoload all widgets from all directories in $zshrc_widget_path that have the
# executable bit set.  The executable bit is not necessary, but gives you an
# easy way to stop the autoloading of a particular shell function.
zshrc_widget_path=("${ZDOTDIR}/widgets")
for func in $^zshrc_widget_path/*(N-.x:t); do
  widget-autoload-register $func
done
fpath=($zshrc_widget_path $fpath)
unset zshrc_widget_path func

zle -N beginning-of-somewhere widget-beginning-or-end-of-somewhere
zle -N end-of-somewhere widget-beginning-or-end-of-somewhere
# Custom widgets:

# a generic accept-line wrapper

# This widget can prevent unwanted autocorrections from command-name
# to _command-name, rehash automatically on enter and call any number
# of builtin and user-defined widgets in different contexts.
#
# For a broader description, see:
# <http://bewatermyfriend.org/posts/2007/12-26.11-50-38-tooltime.html>
#
# The code is imported from the file 'zsh/functions/accept-line' from
# <http://ft.bewatermyfriend.org/comp/zsh/zsh-dotfiles.tar.bz2>, which
# distributed under the same terms as zsh itself.

# A newly added command will may not be found or will cause false
# correction attempts, if you got auto-correction set. By setting the
# following style, we force accept-line() to rehash, if it cannot
# find the first word on the command line in the $command[] hash.
zstyle ':acceptline:*' rehash true

function Accept-Line () {
  setopt localoptions noksharrays
  local -a subs
  local -xi aldone
  local sub
  local alcontext=${1:-$alcontext}

  zstyle -a ":acceptline:${alcontext}" actions subs

  (( ${#subs} < 1 )) && return 0

  (( aldone = 0 ))
  for sub in ${subs} ; do
    [[ ${sub} == 'accept-line' ]] && sub='.accept-line'
    zle ${sub}

    (( aldone > 0 )) && break
  done
}

function Accept-Line-getdefault () {
  emulate -L zsh
  local default_action

  zstyle -s ":acceptline:${alcontext}" default_action default_action
  case ${default_action} in
    ((accept-line|))
    printf ".accept-line"
    ;;
    (*)
      printf ${default_action}
      ;;
  esac
}

function Accept-Line-HandleContext () {
  zle Accept-Line

  default_action=$(Accept-Line-getdefault)
  zstyle -T ":acceptline:${alcontext}" call_default \
    && zle ${default_action}
}

function accept-line () {
  setopt localoptions noksharrays
  local -a cmdline
  local -x alcontext
  local buf com fname format msg default_action

  alcontext='default'
  buf="${BUFFER}"
  cmdline=(${(z)BUFFER})
  com="${cmdline[1]}"
  fname="_${com}"

  Accept-Line 'preprocess'

  zstyle -t ":acceptline:${alcontext}" rehash \
    && [[ -z ${commands[$com]} ]]           \
    && rehash

  if    [[ -n ${com}               ]] \
          && [[ -n ${reswords[(r)$com]} ]] \
          || [[ -n ${aliases[$com]}     ]] \
          || [[ -n ${functions[$com]}   ]] \
          || [[ -n ${builtins[$com]}    ]] \
          || [[ -n ${commands[$com]}    ]] ; then

    # there is something sensible to execute, just do it.
    alcontext='normal'
    Accept-Line-HandleContext

    return
  fi

  if    [[ -o correct              ]] \
          || [[ -o correctall           ]] \
          && [[ -n ${functions[$fname]} ]] ; then

    # nothing there to execute but there is a function called
    # _command_name; a completion widget. Makes no sense to
    # call it on the commandline, but the correct{,all} options
    # will ask for it nevertheless, so warn the user.
    if [[ ${LASTWIDGET} == 'accept-line' ]] ; then
      # Okay, we warned the user before, he called us again,
      # so have it his way.
      alcontext='force'
      Accept-Line-HandleContext

      return
    fi

    if zstyle -t ":acceptline:${alcontext}" nocompwarn ; then
      alcontext='normal'
      Accept-Line-HandleContext
    else
      # prepare warning message for the user, configurable via zstyle.
      zstyle -s ":acceptline:${alcontext}" compwarnfmt msg

      if [[ -z ${msg} ]] ; then
        msg="%c will not execute and completion %f exists."
      fi

      zformat -f msg "${msg}" "c:${com}" "f:${fname}"

      zle -M -- "${msg}"
    fi
    return
  elif [[ -n ${buf//[$' \t\n']##/} ]] ; then
    # If we are here, the commandline contains something that is not
    # executable, which is neither subject to _command_name correction
    # and is not empty. might be a variable assignment
    alcontext='misc'
    Accept-Line-HandleContext

    return
  fi

  # If we got this far, the commandline only contains whitespace, or is empty.
  alcontext='empty'
  Accept-Line-HandleContext
}

zle -N accept-line
zle -N Accept-Line
zle -N Accept-Line-HandleContext

function help-show-abk () {
  zle -M "$(print "Available abbreviations for expansion:"; print -a -C 2 ${(kv)abk})"
}

zle -N help-show-abk

# set number of lines to display per page
HELP_LINES_PER_PAGE=20
# set location of help-zle cache file
HELP_ZLE_CACHE_FILE=~/.cache/zsh_help_zle_lines.zsh
# helper function for help-zle, actually generates the help text
function help_zle_parse_keybindings () {
  emulate -L zsh
  setopt extendedglob
  unsetopt ksharrays  #indexing starts at 1

  # choose files that help-zle will parse for keybindings
  ((${+HELPZLE_KEYBINDING_FILES})) || HELPZLE_KEYBINDING_FILES=( /etc/zsh/zshrc ~/.zshrc.pre ~/.zshrc ~/.zshrc.local )

  if [[ -r $HELP_ZLE_CACHE_FILE ]]; then
    local load_cache=0
    local f
    for f in $HELPZLE_KEYBINDING_FILES; do
      [[ $f -nt $HELP_ZLE_CACHE_FILE ]] && load_cache=1
    done
    [[ $load_cache -eq 0 ]] && . $HELP_ZLE_CACHE_FILE && return
  fi

  #fill with default keybindings, possibly to be overwriten in a file later
  #Note that due to zsh inconsistency on escaping assoc array keys, we encase the key in '' which we will remove later
  local -A help_zle_keybindings
  help_zle_keybindings['<Ctrl>@']="set MARK"
  help_zle_keybindings['<Ctrl>x<Ctrl>j']="vi-join lines"
  help_zle_keybindings['<Ctrl>x<Ctrl>b']="jump to matching brace"
  help_zle_keybindings['<Ctrl>x<Ctrl>u']="undo"
  help_zle_keybindings['<Ctrl>_']="undo"
  help_zle_keybindings['<Ctrl>x<Ctrl>f<c>']="find <c> in cmdline"
  help_zle_keybindings['<Ctrl>a']="goto beginning of line"
  help_zle_keybindings['<Ctrl>e']="goto end of line"
  help_zle_keybindings['<Ctrl>t']="transpose charaters"
  help_zle_keybindings['<Alt>t']="transpose words"
  help_zle_keybindings['<Alt>s']="spellcheck word"
  help_zle_keybindings['<Ctrl>k']="backward kill buffer"
  help_zle_keybindings['<Ctrl>u']="forward kill buffer"
  help_zle_keybindings['<Ctrl>y']="insert previously killed word/string"
  help_zle_keybindings["<Alt>'"]="quote line"
  help_zle_keybindings['<Alt>"']="quote from mark to cursor"
  help_zle_keybindings['<Alt><arg>']="repeat next cmd/char <arg> times (<Alt>-<Alt>1<Alt>0a -> -10 times 'a')"
  help_zle_keybindings['<Alt>u']="make next word Uppercase"
  help_zle_keybindings['<Alt>l']="make next word lowercase"
  help_zle_keybindings['<Ctrl>xd']="preview expansion under cursor"
  help_zle_keybindings['<Alt>q']="push current CL into background, freeing it. Restore on next CL"
  help_zle_keybindings['<Alt>.']="insert (and interate through) last word from prev CLs"
  help_zle_keybindings['<Alt>,']="complete word from newer history (consecutive hits)"
  help_zle_keybindings['<Alt>m']="repeat last typed word on current CL"
  help_zle_keybindings['<Ctrl>v']="insert next keypress symbol literally (e.g. for bindkey)"
  help_zle_keybindings['!!:n*<Tab>']="insert last n arguments of last command"
  help_zle_keybindings['!!:n-<Tab>']="insert arguments n..N-2 of last command (e.g. mv s s d)"
  help_zle_keybindings['<Alt>h']="show help/manpage for current command"

  #init global variables
  unset help_zle_lines help_zle_sln
  typeset -g -a help_zle_lines
  typeset -g help_zle_sln=1

  local k v f cline
  local lastkeybind_desc contents     #last description starting with # that we found
  local num_lines_elapsed=0            #number of lines between last description and keybinding
  #search config files in the order they a called (and thus the order in which they overwrite keybindings)
  for f in $HELPZLE_KEYBINDING_FILES; do
    [[ -r "$f" ]] || continue   #not readable ? skip it
    contents="$(<$f)"
    for cline in "${(f)contents}"; do
      #zsh pattern: matches lines like: # ..............
      if [[ "$cline" == "(#s)[[:space:]]#\#k\#[[:space:]]##(#b)(*)[[:space:]]#(#e)" ]]; then
        lastkeybind_desc="$match[*]"
        num_lines_elapsed=0
        #zsh pattern: matches lines that set a keybinding using bind2map, bindkey or compdef -k
        #             ignores lines that are commentend out
        #             grabs first in '' or "" enclosed string with length between 1 and 6 characters
      elif [[ "$cline" == "[^#]#(bind-maps-by-key-name[[:space:]](*)-s|bindkey|compdef -k)[[:space:]](*)(#b)(\"((?)(#c1,6))\"|\'((?)(#c1,6))\')(#B)(*)" ]]; then
        #description prevously found ? description not more than 2 lines away ? keybinding not empty ?
        if [[ -n $lastkeybind_desc && $num_lines_elapsed -lt 2 && -n $match[1] ]]; then
          #substitute keybinding string with something readable
          k=${${${${${${${match[1]/\\e\^h/<Alt><BS>}/\\e\^\?/<Alt><BS>}/\\e\[5~/<PageUp>}/\\e\[6~/<PageDown>}//(\\e|\^\[)/<Alt>}//\^/<Ctrl>}/3~/<Alt><Del>}
          #put keybinding in assoc array, possibly overwriting defaults or stuff found in earlier files
          #Note that we are extracting the keybinding-string including the quotes (see Note at beginning)
          help_zle_keybindings[${k}]=$lastkeybind_desc
        fi
        lastkeybind_desc=""
      else
        ((num_lines_elapsed++))
      fi
    done
  done
  unset contents
  # Calculate length of keybinding column.
  local kstrlen=0
  for k (${(k)help_zle_keybindings[@]}) ((kstrlen < ${#k})) && kstrlen=${#k}
      #convert the assoc array into preformated lines, which we are able to sort
      for k v in ${(kv)help_zle_keybindings[@]}; do
        #pad keybinding-string to kstrlen chars and remove outermost characters (i.e. the quotes)
        help_zle_lines+=("${(r:kstrlen:)k[2,-2]}${v}")
      done
      #sort lines alphabetically
      help_zle_lines=("${(i)help_zle_lines[@]}")
      [[ -d ${HELP_ZLE_CACHE_FILE:h} ]] || mkdir -p "${HELP_ZLE_CACHE_FILE:h}"
      echo "help_zle_lines=(${(q)help_zle_lines[@]})" >| $HELP_ZLE_CACHE_FILE
      zcompile $HELP_ZLE_CACHE_FILE
}
typeset -g help_zle_sln
typeset -g -a help_zle_lines

# Provides (partially autogenerated) help on keybindings and the zsh line editor
function help-zle () {
  emulate -L zsh
  unsetopt ksharrays  #indexing starts at 1
  #help lines already generated ? no ? then do it
  [[ ${+functions[help_zle_parse_keybindings]} -eq 1 ]] && {help_zle_parse_keybindings && unfunction help_zle_parse_keybindings}
  #already displayed all lines ? go back to the start
  [[ $help_zle_sln -gt ${#help_zle_lines} ]] && help_zle_sln=1
  local sln=$help_zle_sln
  #note that help_zle_sln is a global var, meaning we remember the last page we viewed
  help_zle_sln=$((help_zle_sln + HELP_LINES_PER_PAGE))
  zle -M "${(F)help_zle_lines[sln,help_zle_sln-1]}"
}
zle -N help-zle

function _tmux_pane_words() {
  local expl
  local -a w
  if [[ -z "$TMUX_PANE" ]]; then
    _message "not running inside tmux!"
    return 1
  fi
  w=( ${(u)=$(tmux capture-pane \; show-buffer \; delete-buffer)} )
  _wanted values expl 'words from current tmux pane' compadd -a w
}

zle -C tmux-pane-words-prefix   complete-word _generic
zle -C tmux-pane-words-anywhere complete-word _generic
zstyle ':completion:tmux-pane-words-(prefix|anywhere):*' completer _tmux_pane_words
zstyle ':completion:tmux-pane-words-(prefix|anywhere):*' ignore-line current
zstyle ':completion:tmux-pane-words-anywhere:*' matcher-list 'b:=* m:{A-Za-z}={a-zA-Z}'

# Load a few more functions and tie them to widgets, so they can be bound:

function widget-exists () {
  (( ${+widgets[$1]} ))
}

function keymap-exists () {
  [[ -n ${(M)keymaps:#$1} ]]
}

widget-autoload-register insert-files
widget-autoload-register edit-command-line
widget-autoload-register insert-unicode-char
if autoload history-search-end; then
  zle -N history-beginning-search-backward-end history-search-end
  zle -N history-beginning-search-forward-end  history-search-end
fi
zle -C hist-complete complete-word _generic
zstyle ':completion:hist-complete:*' completer _history

# The actual terminal setup hooks and bindkey-calls:

# Binds a key-binding in provided maps.
# Uses all maps until '--' followed by a key and function.
# bind-maps emacs viins -- '^x.' widget-insert-abbreviation
function bind-maps() {
  local i sequence widget
  local -a maps

  while [[ "$1" != "--" ]]; do
    maps+=( "$1" )
    shift
  done

  # Remove '--'.
  shift
  sequence="$1"
  widget="$2"
  [[ -z "$sequence" ]] && return 1
  for map in "${maps[@]}"; do
    bindkey -M "$map" "$sequence" "$widget"
  done
}

function bind-maps-by-key-name() {
  local i sequence widget
  local -a maps
  while [[ "$1" != "--" ]]; do
    maps+=( "$1" )
    shift
  done

  # Remove '--'.
  shift
  sequence="${key[$1]}"
  widget="$2"
  [[ -z "$sequence" ]] && return 1
  for map in "${maps[@]}"; do
    bindkey -M "$map" "$sequence" "$widget"
  done
}

if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-smkx () {
    emulate -L zsh
    printf '%s' ${terminfo[smkx]}
  }
  function zle-rmkx () {
    emulate -L zsh
    printf '%s' ${terminfo[rmkx]}
  }
  function zle-line-init () {
    zle-smkx
  }
  function zle-line-finish () {
    zle-rmkx
  }
  zle -N zle-line-init
  zle -N zle-line-finish
else
  for i in {s,r}mkx; do
    (( ${+terminfo[$i]} ))
  done
  unset i
fi

typeset -A key
key=(
  Home     "${terminfo[khome]}"
  End      "${terminfo[kend]}"
  Insert   "${terminfo[kich1]}"
  Delete   "${terminfo[kdch1]}"
  Up       "${terminfo[kcuu1]}"
  Down     "${terminfo[kcud1]}"
  Left     "${terminfo[kcub1]}"
  Right    "${terminfo[kcuf1]}"
  PageUp   "${terminfo[kpp]}"
  PageDown "${terminfo[knp]}"
  BackTab  "${terminfo[kcbt]}"
)

# Guidelines for adding key bindings:
#
#   - Do not add hardcoded escape sequences, to enable non standard key
#     combinations such as Ctrl-Meta-Left-Cursor. They are not easily portable.
#
#   - Adding Ctrl characters, such as '^b' is okay; note that '^b' and '^B' are
#     the same key.
#
#   - All keys from the $key[] mapping are obviously okay.
#
#   - Most terminals send "ESC x" when Meta-x is pressed. Thus, sequences like
#     '\ex' are allowed in here as well.

bind-maps-by-key-name emacs             -- Home   beginning-of-line
bind-maps-by-key-name       viins vicmd -- Home   vi-beginning-of-line
bind-maps-by-key-name emacs             -- End    end-of-somewhere
bind-maps-by-key-name       viins vicmd -- End    vi-end-of-line
bind-maps-by-key-name emacs viins       -- Insert overwrite-mode
bind-maps-by-key-name             vicmd -- Insert vi-insert
bind-maps-by-key-name emacs             -- Delete delete-char
bind-maps-by-key-name       viins vicmd -- Delete vi-delete-char
bind-maps-by-key-name emacs viins vicmd -- Up     up-line-or-search
bind-maps-by-key-name emacs viins vicmd -- Down   down-line-or-search
bind-maps-by-key-name emacs             -- Left   backward-char
bind-maps-by-key-name       viins vicmd -- Left   vi-backward-char
bind-maps-by-key-name emacs             -- Right  forward-char
bind-maps-by-key-name       viins vicmd -- Right  vi-forward-char
# Perform abbreviation expansion
bind-maps emacs viins       -- '^x.' widget-insert-abbreviation
# Display list of abbreviations that would expand
bind-maps emacs viins       -- '^xb' help-show-abk
# mkdir -p <dir> from string under cursor or marked area
bind-maps emacs viins       -- '^xM' widget-inplace-mkdirs
# display help for keybindings and ZLE
bind-maps emacs viins       -- '^xz' help-zle
# Insert files and test globbing
bind-maps emacs viins       -- "^xf" insert-files
# Edit the current line in $EDITOR
bind-maps emacs viins       -- '\e:' edit-command-line
# search history backward for entry beginning with typed text
bind-maps emacs viins       -- '^xp' history-beginning-search-backward-end
# search history forward for entry beginning with typed text
bind-maps emacs viins       -- '^xP' history-beginning-search-forward-end
# search history backward for entry beginning with typed text
bind-maps-by-key-name emacs viins       -- PageUp history-beginning-search-backward-end
# search history forward for entry beginning with typed text
bind-maps-by-key-name emacs viins       -- PageDown history-beginning-search-forward-end
bind-maps emacs viins       -- "^x^h" widget-commit-to-history
# Kill left-side word or everything up to next slash
bind-maps emacs viins       -- '\ev' widget-slash-backward-kill-word
# Kill left-side word or everything up to next slash
bind-maps emacs viins       -- '\e^h' widget-slash-backward-kill-word
# Kill left-side word or everything up to next slash
bind-maps emacs viins       -- '\e^?' widget-slash-backward-kill-word
# Do history expansion on space:
bind-maps emacs viins       -- ' ' magic-space
# ^@ is ctrl-space
bind-maps emacs viins       -- '^@' widget-expand-everything
# Trigger menu-complete
bind-maps emacs viins       -- '\ei' menu-complete  # menu completion via esc-i
# Insert a timestamp on the command line (yyyy-mm-dd)
# TODO: This makes C-e really slow, like 600ms
# bind-maps emacs viins       -- '^ed' widget-insert-datestamp
# Insert last typed word
bind-maps emacs viins       -- "\em" widget-insert-last-typed-word
# A smart shortcut for fg<enter>
bind-maps emacs viins       -- '^z' widget-jobs-fg
# prepend the current command with "sudo"
bind-maps emacs viins vicmd     -- "^os" widget-sudo-command-line
# jump to after first word (for adding options)
bind-maps emacs viins       -- '^x1' widget-jump-after-first-word
# complete word from history with menu
bind-maps emacs viins       -- "^x^x" hist-complete

# insert unicode character
# usage example: 'ctrl-x i' 00A7 'ctrl-x i' will give you an §
# See for example http://unicode.org/charts/ for unicode characters code
# Insert Unicode character
bind-maps emacs viins       -- '^xi' insert-unicode-char

bind-maps emacs viins vicmd -- '^r' history-incremental-pattern-search-backward
bind-maps emacs viins vicmd -- '^s' history-incremental-pattern-search-forward

if keymap-exists menuselect; then
  # Shift-tab Perform backwards menu completion
  bind-maps-by-key-name menuselect -- BackTab reverse-menu-complete

  # menu selection: pick item but stay in the menu
  bind-maps menuselect -- '\e^M' accept-and-menu-complete
  # also use + and INSERT since it's easier to press repeatedly
  bind-maps menuselect -- '+' accept-and-menu-complete
  bind-maps-by-key-name menuselect -- Insert accept-and-menu-complete

  # accept a completion and try to complete again by using menu
  # completion; very useful with completing directories
  # by using 'undo' one's got a simple file browser
  bind-maps menuselect -- '^o' accept-and-infer-next-history

  # ^@ is \C-<space>
  bind-maps menuselect -- '^@' accept-and-menu-complete
fi

## use Ctrl-left-arrow and Ctrl-right-arrow for jumping to word-beginnings on
## the command line.
# URxvt sequences:
typeset -a keys_all_modes
# Default for Emacs, but missing in viins and vicmd.
bind-maps emacs viins vicmd -- '\C-a' beginning-of-line
bind-maps emacs viins vicmd -- '\C-e' end-of-line
bind-maps emacs viins vicmd -- '\C-k' kill-line
bind-maps emacs viins vicmd -- '\C-u' kill-whole-line

# Missing from viins
bind-maps emacs viins vicmd -- '\C-p' up-history
bind-maps emacs viins vicmd -- '\C-n' down-history
bind-maps emacs viins vicmd -- '\C-?' backward-delete-char
bind-maps emacs viins vicmd -- '\C-h' backward-delete-char
bind-maps emacs viins vicmd -- '\e.' insert-last-word

bind-maps emacs viins vicmd -- '\eOc' forward-word
bind-maps emacs viins vicmd -- '\eOd' backward-word
# These are for xterm:
bind-maps emacs viins vicmd -- '\e[1;5C' forward-word
bind-maps emacs viins vicmd -- '\e[1;5D' backward-word
## the same for alt-left-arrow and alt-right-arrow
# URxvt again:
bind-maps emacs viins vicmd -- '\e\e[C' forward-word
bind-maps emacs viins vicmd -- '\e\e[D' backward-word
# Xterm again:
bind-maps emacs viins vicmd -- '^[[1;3C' forward-word
bind-maps emacs viins vicmd -- '^[[1;3D' backward-word
# Also try ESC Left/Right:
bind-maps emacs viins vicmd -- '\e'${key[Right]} forward-word
bind-maps emacs viins vicmd -- '\e'${key[Left]}  backward-word

# Ctrl-Delete, the preferred '^'${key[Delete]} didn't work
bind-maps emacs viins vicmd -- '^[[3;5~'  delete-word

bind-maps emacs viins vicmd -- '^x^f^f' widget-select-file
bind-maps emacs viins vicmd -- '^x^f^p' widget-select-bazel-package
bind-maps emacs viins vicmd -- '^x^f^x' widget-select-command


# Spacemacs style bindings.
# Unbind space first.
bindkey -M vicmd -r ' '
bind-maps vicmd -- ' pf' widget-select-file
bind-maps vicmd -- ' pd' widget-select-directory
bind-maps vicmd -- ' pc' widget-select-bazel-package
bind-maps vicmd -- '  ' widget-select-command

bind-maps vicmd -- ' w/' widget-tmux-split-window-horizontal
bind-maps vicmd -- ' w-' widget-tmux-split-window-vertical

bind-maps vicmd -- ' wk' widget-tmux-select-pane-up
bind-maps vicmd -- ' wj' widget-tmux-select-pane-down
bind-maps vicmd -- ' wh' widget-tmux-select-pane-left
bind-maps vicmd -- ' wl' widget-tmux-select-pane-right

bind-maps vicmd -- ' sf' widget-select-tmux-pane-files
bind-maps vicmd -- ' su' widget-select-tmux-pane-urls


# Suckless terminal seems to bind this by default, leave it just in case.
bind-maps emacs viins vicmd -- '\C-V' widget-paste-from-clipboard
bind-maps emacs viins vicmd -- '\C-y' widget-paste-from-clipboard


bind-maps emacs viins vicmd -- '^r' widget-select-history

# Just viins.
bind-maps viins -- 'jk' vi-cmd-mode
bind-maps viins -- 'kj' vi-cmd-mode
bind-maps viins -- '\C-xp' widget-select-command

bind-maps vicmd -- 'H' beginning-of-line
bind-maps vicmd -- 'L' end-of-line

# Keyboard shortcuts.

# Store the current command and use it as the inital text for following
# commands.
bind-maps emacs viins vicmd -- '^[q' push-input

# Fix binding for delete key.
bind-maps emacs viins vicmd -- '^[[P' delete-char

# Add bindings for completions
bind-maps emacs viins vicmd -- '^xt' tmux-pane-words-prefix
bind-maps emacs viins vicmd -- '\M-/' tmux-pane-words-anywhere

typeset -A keymaps_display
keymaps_display=(
  emacs "[emacs]"
  # When in vi mode, main is bound to viins
  main "%{$fg_bold[green]%}[ins]%{$reset_color%}"
  viins "%{$fg_bold[green]%}[ins]%{$reset_color%}"
  vicmd "%{$fg_bold[yellow]%}[cmd]%{$reset_color%}"
  visual "[visual]"
  isearch "[isearch]"
  command "[command]"
  .safe "[.safe]"
)

typeset -A cursor_types
cursor_types=(
  'blinking_block'          '\033[1 q'
  'solid_block'             '\033[2 q'
  'blinking_underbar'       '\033[3 q'
  'solid_underbar'          '\033[4 q'
  'blinking_vertical_bar'   '\033[5 q'
  'solid_vertical_bar'      '\033[6 q'
)
typeset -A cursor_by_keymap
cursor_by_keymap=(
  emacs $cursor_types[solid_block]
  main $cursor_types[solid_vertical_bar]
  viins $cursor_types[solid_vertical_bar]
  vicmd $cursor_types[solid_block]
  visual $cursor_types[solid_block]
  isearch $cursor_types[solid_block]
  command $cursor_types[solid_block]
  .safe $cursor_types[solid_block]
)

function widget-update-vim-prompt() {
  # RPS1="${keymaps_display[$KEYMAP]} ${cursor_by_keymap[$KEYMAP]}"
  # zle reset-prompt
}

zle -N widget-update-vim-prompt

function zle-line-init() {
  if ! is-tty; then
    printf $cursor_by_keymap[$KEYMAP]
  fi
  # zle widget-update-vim-prompt
}

function zle-keymap-select() {
  if ! is-tty; then
    printf $cursor_by_keymap[$KEYMAP]
  fi
  # zle widget-update-vim-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select
