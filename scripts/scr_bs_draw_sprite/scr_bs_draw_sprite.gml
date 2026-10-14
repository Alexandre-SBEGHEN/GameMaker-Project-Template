/**
 * @desc Like draw_sprite_ext, but with better scaling.
 *
 * What is meant by better scaling is that images with a scale larger than one will be depixelized or bicubically interpolated while images with a scale smaller than one will be supersampled.
 * Depixelization here follows the hqnx and xbr methods, which looks at patterns in an image and tries to vectorize them. Making e.g. square dots next to each other turn into lines.
 * Bicubic interpolation looks at the 16 surrounding pixels to mathematically determine a smooth transition between pixels that are being scaled.
 * Supersampling is a downscaling technique that takes the average color over regions of the original image. So downscaling by n, will average a portion of nxn pixels from the original image into 1 for the render target.
 *
 * @param {Asset.GMSprite} sprite The sprite to draw.
 * @param {Real} subimg The sub-image (frame) of the sprite to draw (image_index or -1 correlate to the current frame of animation in the object).
 * @param {Real} x The x coordinate of where to draw the sprite.
 * @param {Real} y The y coordinate of where to draw the sprite.
 * @param {Real} xscale The horizontal scaling of the sprite, as a multiplier: 1 = normal scaling, 0.5 is half, etc.
 * @param {Real} yscale The vertical scaling of the sprite, as a multiplier.: 1 = normal scaling, 0.5 is half, etc.
 * @param {Real} rot The rotation of the sprite. 0=right way up, 90=rotated 90 degrees counter clockwise, etc.
 * @param {Constant.Color} color The color with which to blend the sprite. c_white is to display it normally.
 * @param {Real} alpha The alpha of the sprite (from 0 to 1 where 0 is transparent and 1 opaque).
 * @param {Enum.BSUpscaleMethod} upscale The upscaling method.
 */
function bs_draw_sprite(_sprite, _subimg, _x, _y, _xscale, _yscale, _rot, _color, _alpha, _upscale) {
	var scale_up = ((_xscale > 1 || _yscale > 1) && _upscale != 0), scale_down = (_xscale < 1 || _yscale < 1);

	if (scale_up) {
	    var texture = sprite_get_texture(_sprite, _subimg);
	    switch (_upscale) {
	        case BSUpscaleMethod.UPSCALE_BICUBIC:
	            shader_set(shd_bs_bicubic);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_bicubic, "texel_size"), texture_get_texel_width(texture), texture_get_texel_height(texture));
	            gpu_set_tex_filter(true);
	            break;
            
	        case BSUpscaleMethod.DEPIXEL_HQ4X:
	            shader_set(shd_bs_hq4x);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_hq4x, "texel_size"), texture_get_texel_width(texture), texture_get_texel_height(texture));
	            gpu_set_tex_filter(false);
	            break;
            
	        case BSUpscaleMethod.DEPIXEL_5XBRA:
	            shader_set(shd_bs_5xbra);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbra, "texel_size"), texture_get_texel_width(texture), texture_get_texel_height(texture));
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbra, "texture_size"), 1 / texture_get_texel_width(texture), 1 / texture_get_texel_height(texture));
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbra, "color"), color_get_red(_color) / 255, color_get_green(_color) / 255, color_get_blue(_color) / 255, _alpha);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbra, "color_to_make_transparent"), -1, -1, -1); // Channels from 0 to 1 for the RGB color you want to make transparent. -1 means disabled.
	            gpu_set_tex_filter(false);
	            break;
        
	        case BSUpscaleMethod.DEPIXEL_5XBRB:
	            shader_set(shd_bs_5xbrb);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrb, "texel_size"), texture_get_texel_width(texture), texture_get_texel_height(texture));
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrb, "texture_size"), 1 / texture_get_texel_width(texture), 1 / texture_get_texel_height(texture));
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrb, "color"), color_get_red(_color) / 255, color_get_green(_color) / 255, color_get_blue(_color) / 255, _alpha);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrb, "color_to_make_transparent"), -1, -1, -1); // Channels from 0 to 1 for the RGB color you want to make transparent. -1 means disabled.
	            gpu_set_tex_filter(false);
	            break;
            
	        case BSUpscaleMethod.DEPIXEL_5XBRC:
	            shader_set(shd_bs_5xbrc);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrc, "texel_size"), texture_get_texel_width(texture), texture_get_texel_height(texture));
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrc, "texture_size"), 1 / texture_get_texel_width(texture), 1 / texture_get_texel_height(texture));
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrc, "color"), color_get_red(_color) / 255, color_get_green(_color) / 255, color_get_blue(_color) / 255, _alpha);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrc, "color_to_make_transparent"), -1, -1, -1); // Channels from 0 to 1 for the RGB color you want to make transparent. -1 means disabled.
	            gpu_set_tex_filter(false);
	            break;
	    }
	} else if (scale_down) {
	    var texture, width, height, samples_x, samples_y, max_samples, offset_x, offset_y;
	    texture = sprite_get_texture(_sprite, _subimg);
	    width = sprite_get_width(_sprite); height = sprite_get_height(_sprite);
	    if (_xscale == 0) samples_x = width; else samples_x = min(width, 1 / _xscale);
	    if (_yscale == 0) samples_y = height; else samples_y = min(height, 1 / _yscale);
	    max_samples = max(samples_x, samples_y);
	    offset_x = texture_get_texel_width(texture) * samples_x * 0.5; offset_y = texture_get_texel_height(texture) * samples_y * 0.5;
	    if (max_samples <= 2) {
	        shader_set(shd_bs_supersampling_2x2);
	        shader_set_uniform_f(shader_get_uniform(shd_bs_supersampling_2x2, "offset"), offset_x, offset_y);
	    } else if (max_samples <= 3) {
	        shader_set(shd_bs_supersampling_3x3);
	        shader_set_uniform_f(shader_get_uniform(shd_bs_supersampling_3x3, "offset"), offset_x, offset_y);
	    } else {
	        shader_set(shd_bs_supersampling_4x4);
	        shader_set_uniform_f(shader_get_uniform(shd_bs_supersampling_4x4, "offset"), offset_x, offset_y);
	    }
	    gpu_set_tex_filter(true);
	}

	draw_sprite_ext(_sprite, _subimg, _x, _y, _xscale, _yscale, _rot, _color, _alpha);

	if (scale_up || scale_down) {
	    if (scale_up) gpu_set_tex_filter(true);
	    shader_reset();
	}
	gpu_set_tex_filter(false);
}