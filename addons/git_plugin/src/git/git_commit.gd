#============================================================
#    Git Commit
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 22:53:41
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Commit


static func execute(desc: String):
	desc = desc.strip_edges()
	if desc.left(1) != "\"":
		desc = "\"" + desc
	if desc.right(1) != "\"":
		desc = desc + "\""
	return await GitPlugin_Console.execute(["git commit -m ", desc])
