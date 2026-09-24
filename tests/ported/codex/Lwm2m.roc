# Lwm2m -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText

Lwm2m :: [].{
	Lwm2mObjectId := { id : I64, instance : I64 }.{
		is_eq : Lwm2m.Lwm2mObjectId, Lwm2m.Lwm2mObjectId -> Bool
		is_eq = |a, b| a.id == b.id and a.instance == b.instance
	}
	Lwm2mResourceId := { object_id : I64, instance : I64, resource : I64 }.{
		is_eq : Lwm2m.Lwm2mResourceId, Lwm2m.Lwm2mResourceId -> Bool
		is_eq = |a, b| a.object_id == b.object_id and a.instance == b.instance and a.resource == b.resource
	}
	Lwm2mValue : [Lwm2mString(CceText), Lwm2mInteger(I64), Lwm2mFloat(I64, I64), Lwm2mBoolean(Bool), Lwm2mOpaque(List(I64)), Lwm2mTime(I64)]
	Lwm2mRegistration := { endpoint : CceText, lifetime : I64, binding : CceText, objects : List(I64) }.{
		is_eq : Lwm2m.Lwm2mRegistration, Lwm2m.Lwm2mRegistration -> Bool
		is_eq = |a, b| a.endpoint == b.endpoint and a.lifetime == b.lifetime and a.binding == b.binding and a.objects == b.objects
	}
	LwmFirmwareState : [FwIdle, FwDownloading, FwDownloaded, FwUpdating]

	lwm2m_obj_security : I64
	lwm2m_obj_security = 0

	lwm2m_obj_server : I64
	lwm2m_obj_server = 1

	lwm2m_obj_access_control : I64
	lwm2m_obj_access_control = 2

	lwm2m_obj_device : I64
	lwm2m_obj_device = 3

	lwm2m_obj_connectivity : I64
	lwm2m_obj_connectivity = 4

	lwm2m_obj_firmware : I64
	lwm2m_obj_firmware = 5

	lwm2m_obj_location : I64
	lwm2m_obj_location = 6

	lwm2m_obj_connectivity_stats : I64
	lwm2m_obj_connectivity_stats = 7

	lwm2m_obj_digital_input : I64
	lwm2m_obj_digital_input = 3200

	lwm2m_obj_digital_output : I64
	lwm2m_obj_digital_output = 3201

	lwm2m_obj_temperature : I64
	lwm2m_obj_temperature = 3303

	lwm2m_obj_humidity : I64
	lwm2m_obj_humidity = 3304

	lwm2m_obj_accelerometer : I64
	lwm2m_obj_accelerometer = 3313

	lwm2m_uri : I64, I64, I64 -> CceText
	lwm2m_uri = |object_id, instance_id, resource_id| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("/", CceText.show_int(object_id)), "/"), CceText.show_int(instance_id)), "/"), CceText.show_int(resource_id))

	lwm2m_object_uri : I64, I64 -> CceText
	lwm2m_object_uri = |object_id, instance_id| CceText.concat(CceText.concat(CceText.concat("/", CceText.show_int(object_id)), "/"), CceText.show_int(instance_id))

	lwm2m_tlv_type_resource : I64
	lwm2m_tlv_type_resource = 3

	lwm2m_encode_tlv_resource : I64, List(I64) -> List(I64)
	lwm2m_encode_tlv_resource = |resource_id, value| ({
		len = U64.to_i64_wrap(List.len(value))
		type_byte = (if (resource_id < 256) { (if (len < 8) { I64.bitwise_or(192, len) } else { (if (len < 256) { 200 } else { 216 }) }) } else { (if (len < 8) { I64.bitwise_or(224, len) } else { (if (len < 256) { 232 } else { 248 }) }) })
		id_bytes = (if (resource_id < 256) { [resource_id] } else { [I64.shr_zf_wrap(resource_id, I64.to_u8_wrap(8)), I64.bitwise_and(resource_id, 255)] })
		len_bytes = (if (len < 8) { [] } else { (if (len < 256) { [len] } else { [I64.shr_zf_wrap(len, I64.to_u8_wrap(8)), I64.bitwise_and(len, 255)] }) })
		List.concat(List.concat(List.concat([type_byte], id_bytes), len_bytes), value)
	})

	default_lwm2m_registration : Lwm2m.Lwm2mRegistration
	default_lwm2m_registration = Lwm2m.Lwm2mRegistration.{ endpoint: "codex-device", lifetime: 300, binding: "U", objects: [lwm2m_obj_device, lwm2m_obj_firmware] }

	lwm2m_registration_path : Lwm2m.Lwm2mRegistration -> CceText
	lwm2m_registration_path = |reg| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("/rd?ep=", reg.endpoint), "&lt="), CceText.show_int(reg.lifetime)), "&b="), reg.binding)

	lwm2m_registration_payload : Lwm2m.Lwm2mRegistration -> CceText
	lwm2m_registration_payload = |reg| lwm2m_link_list(reg.objects, 0, U64.to_i64_wrap(List.len(reg.objects)), "")

	lwm2m_link_list : List(I64), I64, I64, CceText -> CceText
	lwm2m_link_list = |objs, i, n, acc| (if (i >= n) { acc } else { ({
		link = CceText.concat(CceText.concat("</", CceText.show_int((List.get(objs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))), ">")
		sep = (if (i > 0) { "," } else { "" })
		lwm2m_link_list(objs, (i + 1), n, CceText.concat(CceText.concat(acc, sep), link))
	}) })

	lwm2m_res_fw_package : I64
	lwm2m_res_fw_package = 0

	lwm2m_res_fw_package_uri : I64
	lwm2m_res_fw_package_uri = 1

	lwm2m_res_fw_update : I64
	lwm2m_res_fw_update = 2

	lwm2m_res_fw_state : I64
	lwm2m_res_fw_state = 3

	lwm2m_res_fw_result : I64
	lwm2m_res_fw_result = 5

	lwm2m_fw_state_value : Lwm2m.LwmFirmwareState -> I64
	lwm2m_fw_state_value = |s| (match s {
		FwIdle => 0
		FwDownloading => 1
		FwDownloaded => 2
		FwUpdating => 3
	})

	lwm2m_res_manufacturer : I64
	lwm2m_res_manufacturer = 0

	lwm2m_res_model : I64
	lwm2m_res_model = 1

	lwm2m_res_serial : I64
	lwm2m_res_serial = 2

	lwm2m_res_firmware_version : I64
	lwm2m_res_firmware_version = 3

	lwm2m_res_reboot : I64
	lwm2m_res_reboot = 4

	lwm2m_res_factory_reset : I64
	lwm2m_res_factory_reset = 5

	lwm2m_res_battery_level : I64
	lwm2m_res_battery_level = 9

	lwm2m_res_memory_free : I64
	lwm2m_res_memory_free = 10

	lwm2m_res_error_code : I64
	lwm2m_res_error_code = 11

	lwm2m_res_current_time : I64
	lwm2m_res_current_time = 13

	eq_Lwm2mValue : Lwm2m.Lwm2mValue, Lwm2m.Lwm2mValue -> Bool
	eq_Lwm2mValue = |ex, ey| (match ex {
		Lwm2mString(exf0) => (match ey {
			Lwm2mString(eyf0) => (exf0 == eyf0)
			_ => False
		})
		Lwm2mInteger(exf0) => (match ey {
			Lwm2mInteger(eyf0) => (exf0 == eyf0)
			_ => False
		})
		Lwm2mFloat(exf0, exf1) => (match ey {
			Lwm2mFloat(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		Lwm2mBoolean(exf0) => (match ey {
			Lwm2mBoolean(eyf0) => (exf0 == eyf0)
			_ => False
		})
		Lwm2mOpaque(exf0) => (match ey {
			Lwm2mOpaque(eyf0) => (exf0 == eyf0)
			_ => False
		})
		Lwm2mTime(exf0) => (match ey {
			Lwm2mTime(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})

	eq_LwmFirmwareState : Lwm2m.LwmFirmwareState, Lwm2m.LwmFirmwareState -> Bool
	eq_LwmFirmwareState = |ex, ey| (match ex {
		FwIdle => (match ey {
			FwIdle => True
			_ => False
		})
		FwDownloading => (match ey {
			FwDownloading => True
			_ => False
		})
		FwDownloaded => (match ey {
			FwDownloaded => True
			_ => False
		})
		FwUpdating => (match ey {
			FwUpdating => True
			_ => False
		})
	})
}
