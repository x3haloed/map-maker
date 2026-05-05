@tool
class_name ValidationIssue
extends Resource

enum Severity { INFO, WARNING, ERROR }

@export var severity: Severity = Severity.ERROR
@export var code: StringName = &"validation.issue"
@export var message: String = ""
@export var node_path: NodePath


static func error(issue_code: StringName, issue_message: String, issue_node_path: NodePath = NodePath()) -> ValidationIssue:
	var issue := ValidationIssue.new()
	issue.severity = Severity.ERROR
	issue.code = issue_code
	issue.message = issue_message
	issue.node_path = issue_node_path
	return issue


static func warning(issue_code: StringName, issue_message: String, issue_node_path: NodePath = NodePath()) -> ValidationIssue:
	var issue := ValidationIssue.new()
	issue.severity = Severity.WARNING
	issue.code = issue_code
	issue.message = issue_message
	issue.node_path = issue_node_path
	return issue
