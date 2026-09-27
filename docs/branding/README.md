# Branding assets

Generated with the built-in imagegen tool. The color logo and template symbol are integrated into the app as of v1.0.3.

- `airdropconverter-logo-concept.png`: approved color logo concept, transparent PNG.
- `menubar-symbol-master.png`: monochrome transparent symbol derived from the logo.
- `MenuBarSymbol.imageset`: 18×18 and 36×36 PNGs, configured for template rendering. Copy this directory into `Assets.xcassets` to use it as `Image("MenuBarSymbol").renderingMode(.template)`.
- `menubar-symbol-preview.png`: light-background size preview; presentation only.

Template rendering uses the alpha mask to select the appropriate foreground color on macOS. The master remains unchanged; the smaller images are resized exports.

## Symbol prompt

Use case: logo-brand. Asset type: macOS menu bar template symbol for AirDropConverter. Input image: reference logo for brand meaning only. Primary request: derive a radically simplified monochrome companion symbol that is legible at 18x18 points. One upright rounded rectangular photo outline, a single simple mountain silhouette inside, and one integrated downward reception/conversion arrow at the lower right. Use flat solid black shapes only with truly transparent negative space and background. Crisp vector-like geometry, consistent thick strokes, generous open gaps, balanced centered square composition with 12 percent padding. Keep the photo-plus-down-arrow identity of the reference but remove the surrounding loop, sun, perspective, bevels, textures and all color. The small arrow must remain clearly recognizable and not collide with the mountain. No text, no mockup, no background plate, no gray shading, no drop shadow, no gradients, no thin details, no multiple variations. A single finished usable template glyph, black foreground opaque and all background transparent.
