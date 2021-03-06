;;; abn-module-debug.el --- Config for debug

;;; Commentary:
;;

;;; Code:
(eval-when-compile
  (require 'use-package))

(use-package abn-funcs-debug
  :ensure nil ; local package
  )

(defvar abn-enable-timed-loads-p t
  "If non-nil, record timing information.")

(defvar abn-timed-load-threshold 0.05
  "Records all `require', `load' calls greater than this threshold.")

(defvar abn-timed-loads-buffer "*load-times*"
  "The buffer to use for timing information.")

(defun abn//debug-log-timing (str &rest args)
  (with-current-buffer abn-timed-loads-buffer
    (goto-char (point-max))
    (insert
     "+"
     (format-time-string
      "%2s.%3N" (time-since before-init-time))
     ": "
     (apply 'format str args)
     "\n")))

(with-current-buffer (get-buffer-create abn-timed-loads-buffer)
  (insert (format "Threshold set at %.3f seconds\n" abn-timed-load-threshold)
          "Emacs start time: "
          (format-time-string "%Y-%m-%d %H:%M:%S.%6N" before-init-time)
          "\n"
          "abn start time:   "
          (format-time-string "%Y-%m-%d %H:%M:%S.%6N" abn-init-time)
          "\n\n"))

(defun abn//record-time-with-desc (description orig-fun &rest args)
  "Records the time with DESCRIPTION for a function ORIG-FUN with ARGS."
  (let ((start (current-time)) result delta)
    (setq result (apply orig-fun args))
    (setq delta (float-time (time-since start)))
    (when (> delta abn-timed-load-threshold)
      (with-current-buffer abn-timed-loads-buffer
        (goto-char (point-max))
        (insert (format "%s %.3f sec\n" description delta))))
    result))


(defun abn//debug-require-timer (orig-fun &rest args)
  "Records slow invocations of `require'."
  (let ((start (current-time)) (feature (car args)) delta)
    (prog1
        (apply orig-fun args)

      (setq delta (float-time (time-since start)))
      (when (> delta abn-timed-load-threshold)
        (abn//debug-log-timing
         "%.3f func=require feature=%s file=%s"
         delta feature load-file-name)))))

(defun abn//debug-load-timer (orig-fun &rest args)
  "Records slow invocations of `load'."
  (let ((start (current-time)) (feature (car args)) delta)
    (prog1
        (apply orig-fun args)

      (setq delta (float-time (time-since start)))
      (when (> delta abn-timed-load-threshold)
        (abn//debug-log-timing
         "%.3f func=load feature=%s file=%s"
         delta feature load-file-name)))))

(defun abn//debug-package-initialize-timer (orig-fun &rest args)
  "Records slow invocations of `package-initialize'."
  (let ((start (current-time)) delta)
    (prog1
        (apply orig-fun args)

      (setq delta (float-time (time-since start)))
      (when (> delta abn-timed-load-threshold)
        (abn//debug-log-timing "%.3f func=package-initialize" delta )))))

;; (when abn-enable-timed-loads-p
;;   (advice-add 'require :around #'abn//debug-require-timer)
;;   (advice-add 'load :around #'abn//debug-load-timer)
;;   (advice-add 'package-initialize :around #'abn//debug-package-initialize-timer))

(provide 'abn-module-debug)
;;; abn-module-debug.el ends here
