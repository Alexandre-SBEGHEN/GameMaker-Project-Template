/**
 * @desc Like draw_sprite_ext, but with better scaling.
 * 
 * What is meant by better scaling is that images with a scale larger than one will be depixelized or bicubically interpolated while images with a scale smaller than one will be supersampled.
 * Depixelization here follows the hqnx and xbr methods, which looks at patterns in an image and tries to vectorize them. Making e.g. square dots next to each other turn into lines.
 * Bicubic interpolation looks at the 16 surrounding pixels to mathematically determine a smooth transition between pixels that are being scaled.
 * Supersampling is a downscaling technique that takes the average color over regions of the original image. So downscaling by n, will average a portion of nxn pixels from the original image into 1 for the render target.
 * 
 * @param {Id.Surface} id The surface to draw.
 * @param {Real} x The x position of where to draw the surface.
 * @param {Real} y The y position of where to draw the surface.
 * @param {Real} xscale The horizontal scale.
 * @param {Real} yscale The vertical scale.
 * @param {Real} rot The rotation or angle to draw the surface.
 * @param {Constant.Color} color The color with which to blend the surface.
 * @param {Real} alpha The alpha transparency for drawing the surface.
 * @param {Enum.BSUpscaleMethod} upscale The upscaling method.
 */
function bs_draw_surface(_id, _x, _y, _xscale, _yscale, _rot, _color, _alpha, _upscale) {
    var scale_up = ((_xscale > 1 || _yscale > 1) && _upscale != 0), scale_down = (_xscale < 1 || _yscale < 1);

	if (scale_up) {
	    switch (_upscale) {
	        case BSUpscaleMethod.UPSCALE_BICUBIC:
	            shader_set(shd_bs_bicubic);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_bicubic, "texel_size"), 1 / surface_get_width(_id), 1 / surface_get_height(_id));
	            gpu_set_texfilter(true);
	            break;
            
	        case BSUpscaleMethod.DEPIXEL_HQ4X:
	            shader_set(shd_bs_hq4x);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_hq4x, "texel_size"), 1 / surface_get_width(_id), 1 / surface_get_height(_id));
	            gpu_set_texfilter(false);
	            break;
            
	        case BSUpscaleMethod.DEPIXEL_5XBRA:
	            shader_set(shd_bs_5xbra);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbra, "texel_size"), 1 / surface_get_width(_id), 1 / surface_get_height(_id));
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbra, "texture_size"), surface_get_width(_id), surface_get_height(_id));
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbra, "color"), color_get_red(_color) / 255, color_get_green(_color) / 255, color_get_blue(_color) / 255, _alpha);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbra, "color_to_make_transparent"), -1, -1, -1); // Channels from 0 to 1 for the RGB color you want to make transparent. -1 means disabled.
	            gpu_set_texfilter(false);
	            break;
        
	        case BSUpscaleMethod.DEPIXEL_5XBRB:
	            shader_set(shd_bs_5xbrb);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrb, "texel_size"), 1 / surface_get_width(_id), 1 / surface_get_height(_id));
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrb, "texture_size"), surface_get_width(_id), surface_get_height(_id));
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrb, "color"), color_get_red(_color) / 255, color_get_green(_color) / 255, color_get_blue(_color) / 255, _alpha);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrb, "color_to_make_transparent"), -1, -1, -1); // Channels from 0 to 1 for the RGB color you want to make transparent. -1 means disabled.
	            gpu_set_texfilter(false);
	            break;
            
	        case BSUpscaleMethod.DEPIXEL_5XBRC:
	            shader_set(shd_bs_5xbrc);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrc, "texel_size"), 1 / surface_get_width(_id), 1 / surface_get_height(_id));
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrc, "texture_size"), surface_get_width(_id), surface_get_height(_id));
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrc, "color"), color_get_red(_color) / 255, color_get_green(_color) / 255, color_get_blue(_color) / 255, _alpha);
	            shader_set_uniform_f(shader_get_uniform(shd_bs_5xbrc, "color_to_make_transparent"), -1, -1, -1); // Channels from 0 to 1 for the RGB color you want to make transparent. -1 means disabled.
	            gpu_set_texfilter(false);
	            break;
	    }
	} else if (scale_down) {
	    var width, height, samples_x, samples_y, max_samples, offset_x, offset_y;
	    width = surface_get_width(_id); height = surface_get_height(_id);
	    if (_xscale == 0) samples_x = width; else samples_x = min(width, 1 / _xscale);
	    if (_yscale == 0) samples_y = height; else samples_y = min(height, 1 / _yscale);
	    max_samples = max(samples_x, samples_y);
	    offset_x = (1 / width) * samples_x * 0.5; offset_y = (1 / height) * samples_y * 0.5;
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
	    gpu_set_texfilter(true);
	}

	draw_surface_ext(_id, _x, _y, _xscale, _yscale, _rot, _color, _alpha);

	if (scale_up || scale_down) {
	    if (scale_up) gpu_set_texfilter(true);
	    shader_reset();
	}
}