extends Object

# 'execute()' gets triggered on event call
# 'target' is the Scene root, aka Textbox

func execute(target):
    print("Hello World! Target: ", target.name)
