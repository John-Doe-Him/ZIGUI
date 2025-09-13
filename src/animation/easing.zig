const std = @import("std");

pub const Easing = struct {
    pub const Function = enum {
        Linear,
        EaseIn,
        EaseOut,
        EaseInOut,
        EaseInBack,
        EaseOutBack,
        EaseInOutBack,
        EaseInElastic,
        EaseOutElastic,
        EaseInOutElastic,
        EaseInBounce,
        EaseOutBounce,
        EaseInOutBounce,
        EaseInSine,
        EaseOutSine,
        EaseInOutSine,
        EaseInQuad,
        EaseOutQuad,
        EaseInOutQuad,
        EaseInCubic,
        EaseOutCubic,
        EaseInOutCubic,
        EaseInQuart,
        EaseOutQuart,
        EaseInOutQuart,
        EaseInQuint,
        EaseOutQuint,
        EaseInOutQuint,
        EaseInExpo,
        EaseOutExpo,
        EaseInOutExpo,
        EaseInCirc,
        EaseOutCirc,
        EaseInOutCirc,
    };

    pub fn apply(easing: Function, t: f32) f32 {
        const clampedT = std.math.clamp(t, 0.0, 1.0);
        
        return switch (easing) {
            .Linear => linear(clampedT),
            .EaseIn => easeInQuad(clampedT),
            .EaseOut => easeOutQuad(clampedT),
            .EaseInOut => easeInOutQuad(clampedT),
            .EaseInBack => easeInBack(clampedT),
            .EaseOutBack => easeOutBack(clampedT),
            .EaseInOutBack => easeInOutBack(clampedT),
            .EaseInElastic => easeInElastic(clampedT),
            .EaseOutElastic => easeOutElastic(clampedT),
            .EaseInOutElastic => easeInOutElastic(clampedT),
            .EaseInBounce => easeInBounce(clampedT),
            .EaseOutBounce => easeOutBounce(clampedT),
            .EaseInOutBounce => easeInOutBounce(clampedT),
            .EaseInSine => easeInSine(clampedT),
            .EaseOutSine => easeOutSine(clampedT),
            .EaseInOutSine => easeInOutSine(clampedT),
            .EaseInQuad => easeInQuad(clampedT),
            .EaseOutQuad => easeOutQuad(clampedT),
            .EaseInOutQuad => easeInOutQuad(clampedT),
            .EaseInCubic => easeInCubic(clampedT),
            .EaseOutCubic => easeOutCubic(clampedT),
            .EaseInOutCubic => easeInOutCubic(clampedT),
            .EaseInQuart => easeInQuart(clampedT),
            .EaseOutQuart => easeOutQuart(clampedT),
            .EaseInOutQuart => easeInOutQuart(clampedT),
            .EaseInQuint => easeInQuint(clampedT),
            .EaseOutQuint => easeOutQuint(clampedT),
            .EaseInOutQuint => easeInOutQuint(clampedT),
            .EaseInExpo => easeInExpo(clampedT),
            .EaseOutExpo => easeOutExpo(clampedT),
            .EaseInOutExpo => easeInOutExpo(clampedT),
            .EaseInCirc => easeInCirc(clampedT),
            .EaseOutCirc => easeOutCirc(clampedT),
            .EaseInOutCirc => easeInOutCirc(clampedT),
        };
    }

    // Linear
    fn linear(t: f32) f32 {
        return t;
    }

    // Sine
    fn easeInSine(t: f32) f32 {
        return 1.0 - std.math.cos((t * std.math.pi) / 2.0);
    }

    fn easeOutSine(t: f32) f32 {
        return std.math.sin((t * std.math.pi) / 2.0);
    }

    fn easeInOutSine(t: f32) f32 {
        return -(std.math.cos(std.math.pi * t) - 1.0) / 2.0;
    }

    // Quadratic
    fn easeInQuad(t: f32) f32 {
        return t * t;
    }

    fn easeOutQuad(t: f32) f32 {
        return 1.0 - (1.0 - t) * (1.0 - t);
    }

    fn easeInOutQuad(t: f32) f32 {
        if (t < 0.5) {
            return 2.0 * t * t;
        } else {
            return 1.0 - std.math.pow(f32, -2.0 * t + 2.0, 2.0) / 2.0;
        }
    }

    // Cubic
    fn easeInCubic(t: f32) f32 {
        return t * t * t;
    }

    fn easeOutCubic(t: f32) f32 {
        return 1.0 - std.math.pow(f32, 1.0 - t, 3.0);
    }

    fn easeInOutCubic(t: f32) f32 {
        if (t < 0.5) {
            return 4.0 * t * t * t;
        } else {
            return 1.0 - std.math.pow(f32, -2.0 * t + 2.0, 3.0) / 2.0;
        }
    }

    // Quartic
    fn easeInQuart(t: f32) f32 {
        return t * t * t * t;
    }

    fn easeOutQuart(t: f32) f32 {
        return 1.0 - std.math.pow(f32, 1.0 - t, 4.0);
    }

    fn easeInOutQuart(t: f32) f32 {
        if (t < 0.5) {
            return 8.0 * t * t * t * t;
        } else {
            return 1.0 - std.math.pow(f32, -2.0 * t + 2.0, 4.0) / 2.0;
        }
    }

    // Quintic
    fn easeInQuint(t: f32) f32 {
        return t * t * t * t * t;
    }

    fn easeOutQuint(t: f32) f32 {
        return 1.0 - std.math.pow(f32, 1.0 - t, 5.0);
    }

    fn easeInOutQuint(t: f32) f32 {
        if (t < 0.5) {
            return 16.0 * t * t * t * t * t;
        } else {
            return 1.0 - std.math.pow(f32, -2.0 * t + 2.0, 5.0) / 2.0;
        }
    }

    // Exponential
    fn easeInExpo(t: f32) f32 {
        if (t == 0.0) return 0.0;
        return std.math.pow(f32, 2.0, 10.0 * (t - 1.0));
    }

    fn easeOutExpo(t: f32) f32 {
        if (t == 1.0) return 1.0;
        return 1.0 - std.math.pow(f32, 2.0, -10.0 * t);
    }

    fn easeInOutExpo(t: f32) f32 {
        if (t == 0.0) return 0.0;
        if (t == 1.0) return 1.0;
        if (t < 0.5) {
            return std.math.pow(f32, 2.0, 20.0 * t - 10.0) / 2.0;
        } else {
            return (2.0 - std.math.pow(f32, 2.0, -20.0 * t + 10.0)) / 2.0;
        }
    }

    // Circular
    fn easeInCirc(t: f32) f32 {
        return 1.0 - std.math.sqrt(1.0 - std.math.pow(f32, t, 2.0));
    }

    fn easeOutCirc(t: f32) f32 {
        return std.math.sqrt(1.0 - std.math.pow(f32, t - 1.0, 2.0));
    }

    fn easeInOutCirc(t: f32) f32 {
        if (t < 0.5) {
            return (1.0 - std.math.sqrt(1.0 - std.math.pow(f32, 2.0 * t, 2.0))) / 2.0;
        } else {
            return (std.math.sqrt(1.0 - std.math.pow(f32, -2.0 * t + 2.0, 2.0)) + 1.0) / 2.0;
        }
    }

    // Back
    fn easeInBack(t: f32) f32 {
        const c1: f32 = 1.70158;
        const c3: f32 = c1 + 1.0;
        
        return c3 * t * t * t - c1 * t * t;
    }

    fn easeOutBack(t: f32) f32 {
        const c1: f32 = 1.70158;
        const c3: f32 = c1 + 1.0;
        
        return 1.0 + c3 * std.math.pow(f32, t - 1.0, 3.0) + c1 * std.math.pow(f32, t - 1.0, 2.0);
    }

    fn easeInOutBack(t: f32) f32 {
        const c1: f32 = 1.70158;
        const c2: f32 = c1 * 1.525;
        
        if (t < 0.5) {
            return (std.math.pow(f32, 2.0 * t, 2.0) * ((c2 + 1.0) * 2.0 * t - c2)) / 2.0;
        } else {
            return (std.math.pow(f32, 2.0 * t - 2.0, 2.0) * ((c2 + 1.0) * (t * 2.0 - 2.0) + c2) + 2.0) / 2.0;
        }
    }

    // Elastic
    fn easeInElastic(t: f32) f32 {
        const c4: f32 = (2.0 * std.math.pi) / 3.0;
        
        if (t == 0.0) return 0.0;
        if (t == 1.0) return 1.0;
        
        return -std.math.pow(f32, 2.0, 10.0 * t - 10.0) * std.math.sin((t * 10.0 - 10.75) * c4);
    }

    fn easeOutElastic(t: f32) f32 {
        const c4: f32 = (2.0 * std.math.pi) / 3.0;
        
        if (t == 0.0) return 0.0;
        if (t == 1.0) return 1.0;
        
        return std.math.pow(f32, 2.0, -10.0 * t) * std.math.sin((t * 10.0 - 0.75) * c4) + 1.0;
    }

    fn easeInOutElastic(t: f32) f32 {
        const c5: f32 = (2.0 * std.math.pi) / 4.5;
        
        if (t == 0.0) return 0.0;
        if (t == 1.0) return 1.0;
        
        if (t < 0.5) {
            return -(std.math.pow(f32, 2.0, 20.0 * t - 10.0) * std.math.sin((20.0 * t - 11.125) * c5)) / 2.0;
        } else {
            return (std.math.pow(f32, 2.0, -20.0 * t + 10.0) * std.math.sin((20.0 * t - 11.125) * c5)) / 2.0 + 1.0;
        }
    }

    // Bounce
    fn easeInBounce(t: f32) f32 {
        return 1.0 - easeOutBounce(1.0 - t);
    }

    fn easeOutBounce(t: f32) f32 {
        const n1: f32 = 7.5625;
        const d1: f32 = 2.75;

        if (t < 1.0 / d1) {
            return n1 * t * t;
        } else if (t < 2.0 / d1) {
            const t2 = t - 1.5 / d1;
            return n1 * t2 * t2 + 0.75;
        } else if (t < 2.5 / d1) {
            const t2 = t - 2.25 / d1;
            return n1 * t2 * t2 + 0.9375;
        } else {
            const t2 = t - 2.625 / d1;
            return n1 * t2 * t2 + 0.984375;
        }
    }

    fn easeInOutBounce(t: f32) f32 {
        if (t < 0.5) {
            return (1.0 - easeOutBounce(1.0 - 2.0 * t)) / 2.0;
        } else {
            return (1.0 + easeOutBounce(2.0 * t - 1.0)) / 2.0;
        }
    }
};