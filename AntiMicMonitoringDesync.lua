obs           = obslua
source_type   = "input"
source_name   = ""
update_interval = 60

-- Slider configuration
min_slider_value      = 1
max_slider_value      = 3600
slider_interval       = 1
default_update_interval = 60

function reset_monitoring()
    local source = obs.obs_get_source_by_name(source_name)
    if source ~= nil then
        local monitoring_type = obs.obs_source_get_monitoring_type(source)
        obs.obs_source_set_monitoring_type(source, obs.OBS_MONITORING_TYPE_NONE)
        print("Monitoring disabled")
        obs.obs_source_set_monitoring_type(source, monitoring_type)
        print("Monitoring enabled")
        obs.obs_source_release(source)
    else
        print("Monitoring device not found with the name " .. source_name)
    end
end

function update_sources(prop)
    local sources = obs.obs_enum_sources()
    obs.obs_property_list_clear(prop)

    if sources ~= nil then
        for _, source in ipairs(sources) do
            local source_id = obs.obs_source_get_id(source)
            if source_type == "" or string.find(source_id, source_type) then
                local name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(prop, name, name)
                print("Device type found: " .. name)
            end
        end
        obs.source_list_release(sources)
    else
        obs.obs_property_list_add_string(prop, "No source found", "No source found")
    end
end

function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "type", "input")
    obs.obs_data_set_default_int(settings, "update_interval", default_update_interval)
end

function script_update(settings)
    source_type   = obs.obs_data_get_string(settings, "type")
    source_name   = obs.obs_data_get_string(settings, "source")
    update_interval = obs.obs_data_get_int(settings, "update_interval")

    obs.timer_remove(reset_monitoring)
    obs.timer_add(reset_monitoring, update_interval * 1000)
end

function script_load(settings)
    source_type   = obs.obs_data_get_string(settings, "type")
    source_name   = obs.obs_data_get_string(settings, "source")
    update_interval = obs.obs_data_get_int(settings, "update_interval")

    obs.timer_add(reset_monitoring, update_interval * 1000)
end

function script_properties()
    local props = obs.obs_properties_create()

    local input_type_list = obs.obs_properties_add_list(
        props, "type", "Source Type", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)

    local source_list = obs.obs_properties_add_list(
        props, "source", "Device", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)

    obs.obs_properties_add_int_slider(props, "update_interval",
        "Update Interval (s):", min_slider_value, max_slider_value, slider_interval)

    update_sources(source_list)

    obs.obs_property_set_modified_callback(input_type_list, function(props, prop, settings)
        source_type = obs.obs_data_get_string(settings, "type")
        update_sources(source_list)
        return true
    end)

    obs.obs_property_list_add_string(input_type_list, "Inputs", "input")
    obs.obs_property_list_add_string(input_type_list, "Outputs", "output")
    obs.obs_property_list_add_string(input_type_list, "All Sources", "")

    return props
end

function script_description()
    return [[
<center><h2>Anti Mic Monitoring Desync</h2></center>
<center><h4>If you run into any problems, open an issue on <a href="https://github.com/MechanicallyDev/OBS-Anti-Mic-Monitoring-Desync">GitHub</a></h4></center>
This script periodically resets the audio monitoring for a selected device to mitigate the buffer buildup issue.
]]
end
