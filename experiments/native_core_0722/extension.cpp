#include "phase.hpp"
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
using namespace godot;

class ApexNativePhase0722 : public RefCounted {
    GDCLASS(ApexNativePhase0722, RefCounted)
protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("phase", "start_mps", "target_mps", "dt_s", "mass_kg",
            "road_n", "max_drive_n", "max_brake_n"), &ApexNativePhase0722::phase);
        ClassDB::bind_method(D_METHOD("phase_batch", "inputs"), &ApexNativePhase0722::phase_batch);
    }
public:
    Dictionary phase(double start, double target, double dt, double mass, double road,
                     double drive, double brake) const {
        apex0722::Output out{};
        Dictionary result;
        if (!apex0722::phase({start,target,dt,mass,road,drive,brake},out)) return result;
        constexpr const char *keys[] = {"speed_mps","distance_m","drive_force_n","brake_force_n",
            "road_load_n","net_force_n","duration_s","drive_work_kj"};
        for (int i=0;i<8;++i) result[keys[i]]=out[i];
        return result;
    }
    // Atomic batch. Empty result means empty request or rejected entire nonempty request.
    PackedFloat64Array phase_batch(const PackedFloat64Array &inputs) const {
        PackedFloat64Array result;
        const int64_t n = inputs.size();
        if (n % 7 != 0 || n > 7 * 4096) return result;
        result.resize((n / 7) * 8);
        if (result.size() != (n / 7) * 8) return PackedFloat64Array();
        for (int64_t i=0;i<n/7;++i) {
            apex0722::Input input{};
            apex0722::Output output{};
            for (int j=0;j<7;++j) input[j]=inputs[i*7+j];
            if (!apex0722::phase(input,output)) return PackedFloat64Array();
            for (int j=0;j<8;++j) result.set(i*8+j,output[j]);
        }
        return result;
    }
};
static void initialize(ModuleInitializationLevel level) {
    if (level == MODULE_INITIALIZATION_LEVEL_SCENE) GDREGISTER_CLASS(ApexNativePhase0722);
}
static void terminate(ModuleInitializationLevel) {}
extern "C" {
GDExtensionBool GDE_EXPORT apex_phase_0722_init(
    GDExtensionInterfaceGetProcAddress get_proc_address,
    GDExtensionClassLibraryPtr library, GDExtensionInitialization *initialization) {
    GDExtensionBinding::InitObject init(get_proc_address,library,initialization);
    init.register_initializer(initialize);
    init.register_terminator(terminate);
    init.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
    return init.init();
}
}
