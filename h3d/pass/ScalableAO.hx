package h3d.pass;

private class SAOShader extends h3d.shader.ScreenShader {

	static var SRC = {

		@const var numSamples : Int;
		@const var numSpiralTurns : Int;

		@param var depthTexture : Sampler2D;
		@param var normalTexture : Sampler2D;
		@param var noiseTexture : Sampler2D;
		@param var noiseScale : Vec2;
		@param var sampleRadius : Float;
		@param var intensity : Float;
		@param var bias : Float;

		@param var cameraView : Mat3x4;
		@param var cameraInverseViewProj : Mat4;

		@param var screenRatio : Vec2;

		function sampleAO(uv : Vec2, position : Vec3, normal : Vec3, radiusSS : Float, tapIndex : Int, rotationAngle : Float) : Float {
			// returns a unit vector and a screen-space radius for the tap on a unit disk
			// (the caller should scale by the actual disk radius)
			// radius relative to radiusSS
			var alpha = (float(tapIndex) + 0.5) * (1.0 / float(numSamples));
			var angle = alpha * (float(numSpiralTurns) * 6.28) + rotationAngle;

			var unitOffset = vec2(cos(angle), sin(angle));
			var targetUV = uv + radiusSS * alpha * unitOffset * screenRatio;
			var Q = getPosition(targetUV);
			var v = Q - position;

			var vv = dot(v, v);
			var vn = dot(v, normal) - (bias / sampleRadius);

			// Smoother transition to zero (lowers contrast, smoothing out corners). [Recommended]
			var radius2 = sampleRadius * sampleRadius;
			var f = max(radius2 - vv, 0.0) / radius2;
			var epsilon = 0.01;
			return f * f * f * max(vn / (epsilon + vv), 0.0);
		}

		function getPosition( uv : Vec2 ) : Vec3 {
			var depth = unpack(depthTexture.get(uv));
			var uv2 = (uv - 0.5) * vec2(2, -2);
			var temp = vec4(uv2, depth, 1) * cameraInverseViewProj;
			var originWS = temp.xyz / temp.w;
			return originWS;
		}

		function fragment() {

			var vUV = input.uv;
			var occlusion = 0.0;
			var origin = getPosition(vUV);
			var normal = unpackNormal(normalTexture.get(vUV));

			var sampleNoise = noiseTexture.get(vUV * noiseScale / screenRatio).x;
			var randomPatternRotationAngle = 2.0 * PI * sampleNoise;

			// is it correct enough to go from WS to DepthUV space ?
			var radiusSS = sampleRadius * 0.5 / (origin * cameraView).z;

			for( i in 0...numSamples )
				occlusion += sampleAO(vUV, origin, normal, radiusSS, i, randomPatternRotationAngle);

			occlusion = 1.0 - occlusion / (5.0 * float(numSamples));
			occlusion = clamp(pow(occlusion, 1.0 + intensity), 0.0, 1.0);

			output.color = vec4(occlusion.xxx, 1.);
		}
	};

	public function new() {
		super();
		numSamples = 20;
		sampleRadius = 1;
		intensity = 1;
		numSpiralTurns = 7;
		bias = 0.01;
		noiseScale.set(10, 10);
		noiseTexture = getNoise(128);
		noiseTexture.wrap = Repeat;
	}

	public function getNoise(size) {
		var b = new hxd.BitmapData(size, size);
		for( x in 0...size )
			for( y in 0...size ) {
				var n = Std.random(256);
				b.setPixel(x, y, 0xFF000000 | n | (n << 8) | (n << 16));
			}
		var t = h3d.mat.Texture.fromBitmap(b);
		b.dispose();
		return t;
	}

}

class ScalableAO extends h3d.pass.ScreenFx<SAOShader> {

	public function new() {
		super(new SAOShader());
	}

	public function apply( depthTexture : h3d.mat.Texture, normalTexture : h3d.mat.Texture, camera : h3d.Camera ) {
		shader.depthTexture = depthTexture;
		shader.normalTexture = normalTexture;
		shader.cameraView = camera.mcam;
		shader.cameraInverseViewProj = camera.getInverseViewProj();
		shader.screenRatio.set(engine.height / engine.width, 1);
		render();
	}

}