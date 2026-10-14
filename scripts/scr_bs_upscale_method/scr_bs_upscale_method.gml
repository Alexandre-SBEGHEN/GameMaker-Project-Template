/**
 * @desc Upcsaling methods used in better scaling.
 * 
 * 5xbr does not have full alpha support, but below you can set a color to act as transparency.
 * 
 * Use COUNT to get the number of methods.
 */
enum BSUpscaleMethod {
    NO_UPSCALE, // No upscale shader.
    UPSCALE_BICUBIC, // Bicubic upscale shader.
    DEPIXEL_HQ4X, // hq4x depixelization (full alpha support, but more jaggy than 5xbr).
    DEPIXEL_5XBRA, // 5xbra depixelization (round).
    DEPIXEL_5XBRB, // 5xbrb depixelization (semi-round).
    DEPIXEL_5XBRC, // 5xbrc depixelization (square).
    COUNT
}