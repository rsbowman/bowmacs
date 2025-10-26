;;; bowmacs-ai.el --- Use gptel in a convenient way  -*- lexical-binding: t; -*-

;; Author: R. Sean Bowman
;; Version 1.0
;;

;;; Commentary:

;; This package provides some convenient ways to interact with gtpel
;; from any Emacs buffer.

;;; Code:
(require 'gptel)

(defvar bowmacs-ai-default-major-mode 'markdown-mode
  "Major mode to use for bowmacs-ai buffers.")

(defvar bowmacs-ai-major-mode-alist
  '((text-mode . text-mode))
  "Override bowmacs-ai buffer mode for a given original buffer mode.")

(defvar bowmacs-ai-original-window-config nil
  "Original window configuration before opening the `bowmacs-ai' buffer.")

(make-variable-buffer-local 'bowmacs-ai-original-window-config)

(defvar bowmacs-ai-buffer-name "*bowmacs-ai*"
  "Name of the bowmacs-ai buffer.")

(defun bowmacs--gptel-request ()
  "Wrap gptel to remove goofy system prompt."
  (interactive)
  (gptel-request nil :stream t :system ""))

(define-minor-mode bowmacs-ai-mode
  "Minor mode for the GPT-4 interaction buffer."
  :lighter " GPT-4"
  :keymap (let ((map (make-sparse-keymap)))
            ;; (define-key map (kbd "C-c s") #'gptel-send)
            (define-key map (kbd "C-c s") #'bowmacs--gptel-request)
            (define-key map (kbd "C-c k") #'bowmacs-ai-cancel)
            (define-key map (kbd "C-c C-c") #'bowmacs-ai-complete)
            map))

;; TODO: can we have multiple bowmacs-ai buffers?
;;

(defun bowmacs-ai-open-with-prompt (prompt)
  "Open *bowmacs-ai* buffer with a given `PROMPT'."
  (let ((window-config (current-window-configuration))
        (selected-text (if (use-region-p)
                           (buffer-substring-no-properties (region-beginning) (region-end))
                         ""))
        (original-mode major-mode)
        (ai-buffer-name bowmacs-ai-buffer-name))
    (switch-to-buffer-other-window ai-buffer-name)
    (erase-buffer)
    (when (not (string-equal prompt ""))
      (insert prompt "\n"))
    (when (not (string-equal selected-text ""))
      (insert "\n```\n" selected-text "```\n")
      ;; OLD: move cursor to before selected-text
      ;; (let ((start (point))
      ;;       (_ (insert "\n```\n" selected-text "```\n"))
      ;;       (end (point)))
      ;;   (forward-line (- (count-lines start end))))
      )
    (let ((mode (alist-get original-mode bowmacs-ai-major-mode-alist bowmacs-ai-default-major-mode)))
      (funcall mode))
    (bowmacs-ai-mode)
    (setq-local bowmacs-ai-original-window-config window-config)))

;;;###autoload
(defun bowmacs-ai-open ()
  "Open the *bowmacs-ai* buffer with empty prompt."
  (interactive)
  (bowmacs-ai-open-with-prompt ""))

(defun bowmacs-ai-cancel ()
  "Close the AI buffer without modifying the original buffer."
  (interactive)
  (let ((ai-buffer (current-buffer)))
    (set-window-configuration bowmacs-ai-original-window-config)
    (kill-buffer ai-buffer)))

(defun bowmacs-ai-complete ()
  "Close the AI buffer and possibly insert into the original buffer.

Replace selected text in the original buffer with the text
selected or the whole content in the bowmacs-ai buffer."
  (interactive)
  (let ((replacement-text (if (use-region-p)
                              (buffer-substring (region-beginning) (region-end))
                            ""))
        (ai-buffer (current-buffer)))
    (set-window-configuration bowmacs-ai-original-window-config)
    (kill-buffer ai-buffer)
    (when (use-region-p)
      (delete-region (region-beginning) (region-end))
      (insert replacement-text))))

(defmacro bowmacs-ai-define-opener (prompt-type prompt)
  "Define a fn bowmacs-ai-opener-`PROMPT-TYPE' using `PROMPT'."
  (let* ((prompt-type-str (symbol-name prompt-type))
         (function-name (intern (concat "bowmacs-ai-open-" prompt-type-str))))
    `(defun ,function-name ()
       ,(format "Open a bowmacs-ai buffer w/ prompt `%s'" prompt-type-str)
       (interactive)
       (bowmacs-ai-open-with-prompt ,prompt))))

(provide 'bowmacs-ai)
;;; bowmacs-ai.el ends here
