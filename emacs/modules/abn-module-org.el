;;; abn-module-org.el --- Config for org

;;; Commentary:
;;

;;; Code:
(eval-when-compile
  (require 'use-package))

(use-package abn-funcs-org
  :defer t
  :ensure nil ; local package
  :general
  (abn/define-leader-keys
   ",dd" 'abn/org-set-tag-as-drill
   ",dt" 'abn/org-drill-create-template
   ",dc" 'abn/org-drill-create-template-cloze)
  :init
  (abn-declare-prefix ",d" "org drill"))

(use-package org
  :defer t
  :ensure org-plus-contrib
  :general
  (general-evil-define-key 'normal org-mode-map
    "TAB" 'org-cycle)
  (general-evil-define-key '(normal insert) org-mode-map
    "M-l" 'org-metaright
    "M-h" 'org-metaleft
    "M-k" 'org-metaup
    "M-j" 'org-metadown
    "M-L" 'org-shiftmetaright
    "M-H" 'org-shiftmetaleft
    "M-K" 'org-shiftmetaup
    "M-J" 'org-shiftmetadown)

  :config
  (abn/define-leader-keys-for-major-mode 'org-mode
    "'" 'org-edit-special
    "c" 'org-capture
    "d" 'org-deadline
    "D" 'org-insert-drawer
    "ee" 'org-export-dispatch
    "f" 'org-set-effort
    "P" 'org-set-property
    ":" 'org-set-tags

    "a" 'org-agenda
    "b" 'org-tree-to-indirect-buffer
    "A" 'org-archive-subtree
    "l" 'org-open-at-point
    "T" 'org-show-todo-tree

    "." 'org-time-stamp
    "!" 'org-time-stamp-inactive

    ;; headings
    "hi" 'org-insert-heading-after-current
    "hI" 'org-insert-heading
    "hs" 'org-insert-subheading

    ;; More cycling options (timestamps, headlines, items, properties)
    "L" 'org-shiftright
    "H" 'org-shiftleft
    "J" 'org-shiftdown
    "K" 'org-shiftup

    ;; Change between TODO sets
    "C-S-l" 'org-shiftcontrolright
    "C-S-h" 'org-shiftcontrolleft
    "C-S-j" 'org-shiftcontroldown
    "C-S-k" 'org-shiftcontrolup

    ;; Subtree editing
    "Sl" 'org-demote-subtree
    "Sh" 'org-promote-subtree
    "Sj" 'org-move-subtree-down
    "Sk" 'org-move-subtree-up

    ;; tables
    "ta" 'org-table-align
    "tb" 'org-table-blank-field
    "tc" 'org-table-convert
    "tdc" 'org-table-delete-column
    "tdr" 'org-table-kill-row
    "te" 'org-table-eval-formula
    "tE" 'org-table-export
    "th" 'org-table-previous-field
    "tH" 'org-table-move-column-left
    "tic" 'org-table-insert-column
    "tih" 'org-table-insert-hline
    "tiH" 'org-table-hline-and-move
    "tir" 'org-table-insert-row
    "tI" 'org-table-import
    "tj" 'org-table-next-row
    "tJ" 'org-table-move-row-down
    "tK" 'org-table-move-row-up
    "tl" 'org-table-next-field
    "tL" 'org-table-move-column-right
    "tn" 'org-table-create
    "tN" 'org-table-create-with-table.el
    "tr" 'org-table-recalculate
    "ts" 'org-table-sort-lines
    "ttf" 'org-table-toggle-formula-debugger
    "tto" 'org-table-toggle-coordinate-overlays
    "tw" 'org-table-wrap-region

    ;; Multi-purpose keys
    (or abn-major-mode-leader-key ",") 'org-ctrl-c-ctrl-c
    "*" 'org-ctrl-c-star
    "RET" 'org-ctrl-c-ret
    "-" 'org-ctrl-c-minus
    "^" 'org-sort
    "/" 'org-sparse-tree

    "I" 'org-clock-in
    "n" 'org-narrow-to-subtree
    "N" 'widen
    "O" 'org-clock-out
    "q" 'org-clock-cancel
    "R" 'org-refile
    "s" 'org-schedule

    ;; insertion of common elements
    "ia" 'org-attach
    "il" 'org-insert-link
    "if" 'org-footnote-new)

  ;; Don't indent under headers.
  (setq org-adapt-indentation nil))

(use-package org-drill
  :defer t
  :ensure org-plus-contrib
  :commands (org-drill)
  :config
  ;; Config options
  )

(use-package org-babel
  :defer t
  :disabled ;; TODO: lazy load me
  :ensure nil
  :init
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (python . t)
     (sh . t)
     (shell . t)
     (haskell . t)
     (js . t)
     (latex . t)
     (gnuplot . t)
     (C . t)
     (sql . t)
     (ditaa . t)))
  :config
  ;; Don't ask to eval code in SRC blocks.
  (setq org-confirm-babel-evaluate nil))

(provide 'abn-module-org)
;;; abn-module-org.el ends here