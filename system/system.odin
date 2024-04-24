package system

import    "vendor:glfw"
import vk "vendor:vulkan"
import    "core:mem"


Members :: struct {
	Window : glfw.WindowHandle,
	Instance : vk.Instance,
}

m : Members

WIDTH : i32 : 800
HEIGHT : i32 : 600

run :: proc() {
	initWindow()
	initVulkan()
	mainLoop()
	cleanUp()
	return
}


@(private="file")
initWindow :: proc() {
	glfw.Init()
	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	glfw.WindowHint(glfw.RESIZABLE, glfw.FALSE)
	m.Window = glfw.CreateWindow(WIDTH, HEIGHT, "Vulkan", nil, nil)
	assert(m.Window != nil, "glfwCreateWindow failed!")
	return
}

@(private="file")
initVulkan :: proc() {
	createInstance()
	return
}

@(private)
createInstance :: proc() {
	// First we create the application info to be used in the create info
	appInfo : vk.ApplicationInfo
	appInfo.sType = vk.StructureType.APPLICATION_INFO
	appInfo.pApplicationName = "Hello Triangle"
	appInfo.pEngineName = "No Engine"
	appInfo.engineVersion = vk.MAKE_VERSION(1, 3, 0)
	appInfo.applicationVersion = vk.MAKE_VERSION(1, 3, 0)
	appInfo.apiVersion = vk.API_VERSION_1_3

	// We create the instance create info used in the create instance function
	createInfo : vk.InstanceCreateInfo = {}
	createInfo.sType = vk.StructureType.INSTANCE_CREATE_INFO
	createInfo.pApplicationInfo = &appInfo
	
	extensions := glfw.GetRequiredInstanceExtensions()
	glfwExtensionCount := u32(len(extensions))
	glfwExtensions := mem.raw_data(extensions)

	createInfo.enabledExtensionCount = glfwExtensionCount
	createInfo.ppEnabledExtensionNames = glfwExtensions

	createInfo.enabledLayerCount = 0
	
	assert(vk.CreateInstance(&createInfo, nil, &m.Instance) != vk.Result.SUCCESS, "vkCreateInstance failed!")

	return
}

@(private="file")
mainLoop :: proc() {
	for !glfw.WindowShouldClose(m.Window) {
		glfw.PollEvents()
	}
	return
}

@(private="file")
cleanUp :: proc() {
	vk.DestroyInstance(m.Instance, nil)
	glfw.DestroyWindow(m.Window)
	glfw.Terminate()
	return
}