// Import and register all your controllers with relative paths for esbuild bundling
import { application } from "./application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import SearchController from "./search_controller"
import SearchableSelectController from "./searchable_select_controller"
import CollapsibleController from "./collapsible_controller"
import VariableDrawerController from "./variable_drawer_controller"
import BranchSelectController from "./projects/settings/branch_select_controller"
import TagSelectController from "./projects/settings/tag_select_controller"
import AvatarPreviewController from "./avatar_preview_controller"
import MarkdownEditorController from "./markdown_editor_controller"
import UserSelectDropdownController from "./user_select_dropdown_controller"
import LabelSelectDropdownController from "./label_select_dropdown_controller"
import EpicSelectDropdownController from "./epic_select_dropdown_controller"
import ReplyToggleController from "./reply_toggle_controller"
import CopyController from "./copy_controller"
import ClipboardController from "./clipboard_controller"
import UsersSettingsKeysController from "./users/settings/keys_controller"
import DiffCommentController from "./diff_comment_controller"
import DiffNavigatorController from "./diff_navigator_controller"
import ColorPickerController from "./color_picker_controller"
import StageLabelSearchController from "./stage_label_search_controller"
import FlashMessageController from "./flash_message_controller"
import BoardDragController from "./projects/board_drag_controller"
import DashboardController from "./dashboard_controller"
import ToggleController from "./toggle_controller"
import ReplyFormController from "./reply_form_controller"
import MrBranchSelectController from "./mr_branch_select_controller"
import RefSelectorController from "./ref_selector_controller"
import LinkItemFormController from "./link_item_form_controller"
import PipelineRefSelectController from "./pipeline_ref_select_controller"
import CiLintController from "./ci_lint_controller"
import EmailChangeController from "./email_change_controller"

// Register controllers manually to ensure they're loaded
application.register("search", SearchController)
application.register("searchable-select", SearchableSelectController)
application.register("collapsible", CollapsibleController)
application.register("variable-drawer", VariableDrawerController)
application.register("branch-select", BranchSelectController)
application.register("tag-select", TagSelectController)
application.register("avatar-preview", AvatarPreviewController)
application.register("markdown-editor", MarkdownEditorController)
application.register("user-select-dropdown", UserSelectDropdownController)
application.register("label-select-dropdown", LabelSelectDropdownController)
application.register("epic-select-dropdown", EpicSelectDropdownController)
application.register("reply-toggle", ReplyToggleController)
application.register("copy", CopyController)
application.register("clipboard", ClipboardController)
application.register("users--settings--keys", UsersSettingsKeysController)
application.register("diff-comment", DiffCommentController)
application.register("diff-navigator", DiffNavigatorController)
application.register("color-picker", ColorPickerController)
application.register("stage-label-search", StageLabelSearchController)
application.register("flash-message", FlashMessageController)
application.register("board-drag", BoardDragController)
application.register("dashboard", DashboardController)
application.register("toggle", ToggleController)
application.register("reply-form", ReplyFormController)
application.register("mr-branch-select", MrBranchSelectController)
application.register("ref-selector", RefSelectorController)
application.register("link-item-form", LinkItemFormController)
application.register("pipeline-ref-select", PipelineRefSelectController)
application.register("ci-lint", CiLintController)
application.register("email-change", EmailChangeController)

eagerLoadControllersFrom("controllers", application)
