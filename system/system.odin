package system

import    "vendor:glfw"
import vk "vendor:vulkan"
import    "core:mem"


WIDTH : i32 : 800
HEIGHT : i32 : 600
window : glfw.WindowHandle
instance : vk.Instance

run :: proc() {
	initWindow()
	initVulkan()
	defer cleanUp()
	mainLoop()
	return
}

initWindow :: proc() {
	glfw.Init()
	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	glfw.WindowHint(glfw.RESIZABLE, glfw.FALSE)
	window = glfw.CreateWindow(WIDTH, HEIGHT, "Vulkan", nil, nil)
	assert(window != nil, "glfwCreateWindow failed!")
	return
}

initVulkan :: proc() {
	createInstance()
	return
}

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
	glfwExtensions : [^]cstring = mem.raw_data(extensions)

	createInfo.enabledExtensionCount = glfwExtensionCount
	createInfo.ppEnabledExtensionNames = glfwExtensions

	createInfo.enabledLayerCount = 0

	assert(vk.CreateInstance(&createInfo, nil, &instance) != vk.Result.SUCCESS, "vkCreateInstance failed!")

	return
}

mainLoop :: proc() {
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()
	}
	return
}

cleanUp :: proc() {
	vk.DestroyInstance(instance, nil)
	glfw.DestroyWindow(window)
	glfw.Terminate()
	return
}