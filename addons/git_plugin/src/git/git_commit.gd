#============================================================
#    Git Commit
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 22:53:41
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Commit


static func execute(desc: String):
	desc = JSON.stringify(desc.strip_edges())
	return await GitPlugin_Console.execute(["git commit -m ", desc])
