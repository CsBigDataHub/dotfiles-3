;;; abn-module-langs.el --- Config for smallish languages

;;; Commentary:
;;

;;; Code:
(eval-when-compile
  (require 'use-package))

(use-package abn-funcs-langs
  :ensure nil ; local package
  :defer t
  :commands
  (abn/go-mode-hook-init-format-on-save
   abn//switch-to-zsh-mode-by-file-name))

(use-package css-mode
  :defer t
  :ensure nil ; built-in
  :init
  (setq css-indent-offset 2))

(use-package json-mode
  :defer t
  :mode
  (("\\.json\\'" . json-mode)
   ("\\.firebaserc\\'" . json-mode)))

(use-package go-mode
  :defer t
  :mode (("\\.go\\'" . go-mode))
  :init
  (add-hook 'go-mode-hook 'abn/go-mode-hook-init-format-on-save))

(use-package protobuf-mode
  :defer t
  :mode (("\\.proto\\'" . protobuf-mode)))

(use-package rust-mode
  :defer t
  :mode
  (("\\.rs\\'" . rust-mode))
  :init
  (setq rust-format-on-save t))

(use-package scala-mode
  :defer t
  :mode
  (("\\.scala\\'" . scala-mode)))

(use-package sh-mode
  :defer t
  :ensure nil ; built-in
  :init
  (add-to-list 'auto-mode-alist '("prompt_pure_setup" . sh-mode))
  (add-hook 'sh-mode-hook #'abn//switch-to-zsh-mode-by-file-name))

(use-package sbt-mode
  :defer t
  :mode
  (("\\.sbt\\'" . sbt-mode)))

(use-package terraform-mode
  :defer t
  :mode
  (("\\.tf\\'" . terraform-mode)))

(use-package typescript-mode
  :defer t
  :mode (("\\.ts\\'". typescript-mode)))

(use-package vimrc-mode
  :defer t
  :mode
  (("ideavimrc\\'" . vimrc-mode)))

(use-package yaml-mode
  :defer t
  :mode
  (("\\.yml\\'" . yaml-mode)))

(provide 'abn-module-langs)
;;; abn-module-langs.el ends here
