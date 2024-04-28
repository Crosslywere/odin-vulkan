package system

import    "vendor:glfw"
import vk "vendor:vulkan"
import    "core:fmt"
import    "base:runtime"
import    "core:log"

WIDTH : i32 : 800
HEIGHT : i32 : 600
window : glfw.WindowHandle
instance : vk.Instance
ENABLE_VALIDATION_LAYER :: ODIN_DEBUG
validationLayers : []string = { "VK_LAYER_KHRONOS_validation" }
debugMessenger : vk.DebugUtilsMessengerEXT
ctx : runtime.Context
physicalDevice : vk.PhysicalDevice

run :: proc() {
	context.logger = log.create_console_logger()
	ctx = context
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
	setupDebugMessenger()
	pickPhysicalDevice()
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

	extensions := getRequiredExtensions()
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

getRequiredExtensions :: proc() -> (extensions : [dynamic]cstring) {
	exts := glfw.GetRequiredInstanceExtensions()
	for ext in exts {
		append_elem(&extensions, ext)
	}
	if ENABLE_VALIDATION_LAYER {
		append_elem(&extensions, vk.EXT_DEBUG_UTILS_EXTENSION_NAME)
	}
	return
}

debugCallback :: proc(messageSeverity: vk.DebugUtilsMessageSeverityFlagsEXT, messageTypes: vk.DebugUtilsMessageTypeFlagsEXT, pCallbackData: ^vk.DebugUtilsMessengerCallbackDataEXT, pUserData: rawptr) -> (result : b32 = false) {
	context = context
	fmt.printfln("Validation layer: %s", pCallbackData.pMessage)
	return
}

setupDebugMessenger :: proc() {
	if !ENABLE_VALIDATION_LAYER do return
	createInfo : vk.DebugUtilsMessengerCreateInfoEXT
	populateDebugMessengerCreateInfo(&createInfo)
	assert(vk.CreateDebugUtilsMessengerEXT(instance, &createInfo, nil, &debugMessenger) == .SUCCESS, "failed to setup debug messenger")
	return
}

populateDebugMessengerCreateInfo :: proc(createInfo : ^vk.DebugUtilsMessengerCreateInfoEXT) {
	createInfo.sType = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT
	createInfo.messageSeverity |= { .ERROR, .WARNING, .VERBOSE }
	createInfo.messageType |= { .GENERAL, .VALIDATION, .PERFORMANCE }
	createInfo.pfnUserCallback = auto_cast debugCallback
	return
}

pickPhysicalDevice :: proc() {
	deviceCount : u32
	vk.EnumeratePhysicalDevices(instance, &deviceCount, nil)
	if deviceCount == 0 do panic("failed to find a GPU that supports vulkan")
	devices := make([]vk.PhysicalDevice, deviceCount)
	vk.EnumeratePhysicalDevices(instance, &deviceCount, raw_data(devices))
	score := 0
	for i in 0 ..< deviceCount {
		deviceScore := scoreDevice(devices[i])
		if score < deviceScore {
			score = deviceScore
			physicalDevice = devices[i]
		}
	}
	assert(physicalDevice != nil, "failed to find suitable GPU")
	return
}

scoreDevice :: proc(device : vk.PhysicalDevice) -> (score : int = 0) {
	if properties, features, result := isDeviceSuitable(device); result {
		score += 1
		// TODO: Score based on required features
	}
	return
}

isDeviceSuitable :: proc(device : vk.PhysicalDevice) -> (properties : vk.PhysicalDeviceProperties, features : vk.PhysicalDeviceFeatures, result : bool = false) {
	vk.GetPhysicalDeviceProperties(device, &properties)
	vk.GetPhysicalDeviceFeatures(device, &features)
	result = auto_cast (features.geometryShader)
	return
}

mainLoop :: proc() {
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()
	}
	return
}

cleanUp :: proc() {
	if ENABLE_VALIDATION_LAYER {
		vk.DestroyDebugUtilsMessengerEXT(instance, debugMessenger, nil)
	}
	vk.DestroyInstance(instance, nil)
	glfw.DestroyWindow(window)
	glfw.Terminate()
	return
}