package system

import    "vendor:glfw"
import vk "vendor:vulkan"

WIDTH : i32 : 800
HEIGHT : i32 : 600
window : glfw.WindowHandle
instance : vk.Instance
ENABLE_VALIDATION_LAYER :: ODIN_DEBUG
validationLayers : []string = { "VK_LAYER_KHRONOS_validation" }

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
	vk.load_proc_addresses_global(cast(rawptr)glfw.GetInstanceProcAddress)
	createInstance()
	return
}

createInstance :: proc() {
	if ENABLE_VALIDATION_LAYER && !checkValidationLayers() {
		panic("vaildation layers requested, but not available")
	}
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
	glfwExtensions : [^]cstring = raw_data(extensions)

	createInfo.enabledExtensionCount = glfwExtensionCount
	createInfo.ppEnabledExtensionNames = glfwExtensions

	createInfo.enabledLayerCount = 0

	assert(vk.CreateInstance(&createInfo, nil, &instance) == .SUCCESS, "vkCreateInstance failed!")

	vk.load_proc_addresses_instance(instance)

	return
}

checkValidationLayers :: proc() -> (result := false) {
	layerCount : u32
	vk.EnumerateInstanceLayerProperties(&layerCount, nil)
	availableLayers := make([]vk.LayerProperties, layerCount)
	vk.EnumerateInstanceLayerProperties(&layerCount, raw_data(availableLayers))
	for validationLayer in validationLayers {
		for layer in 0 ..< layerCount {
			layerFound := false
			for i := 0; i < len(validationLayer); {
				if validationLayer[i] == availableLayers[layer].layerName[i] {
					i += 1
					if i == vk.MAX_DESCRIPTION_SIZE && i < len(validationLayer) {
						break
					}
					if availableLayers[layer].layerName[i] == 0 {
						layerFound = true
						break
					}
					continue
				}
				break
			}
			if layerFound {
				result = true
				break
			}
		}
	}
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