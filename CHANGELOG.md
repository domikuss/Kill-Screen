## Release Notes

## [2.0.1]

### Fixes:
- Fixed error Invalid database Handle 0 (error: 4)

## [2.0.0]

### Innovations:
- Added possibility to select a fading effect with adjustable color.
- Added possibility to set FOV.
- Shop:
    - Added possibility to set product description.
    - Added possibility to set luck chance.
    - Added possibility to hide items. (To give via admin menu, or to receive by testing your luck.)
    - Shop category changed to "killscreen_effects".
    - Added support for translation of category names and descriptions.

- Added possibility to add several effects using configuration file.
- Reworked VIP and Shop menu.
- Renamed plugin file name from "Kill-Screen" to "killscreen". (The old one must be removed.)
- Added separate translation file. (No need to add translation to "vip_modules.phrases.txt" now.)
- A plugin can now compile if one of the libraries is missing: VIP or Shop. (If both libraries are unavailable, the plugin will not compile.)
- Added option to ignore VIP or Shop code by commenting out lines with INCLUDE_VIP or INCLUDE_SHOP. (The code will not be added to the compiled plugin.)

### Configuration file:
- The name of the effect and has support for translations. If a section with the name of the effect is added to the translation file, the effect will be translated, otherwise the value from the configuration file will be used.
- Keys "add_to_vip_by_default", "add_to_shop_by_default" determine whether to add all effects to VIP/Shop by default or not. (1 = yes, 0 = no)
- Key "fade_rgba" allows to set the color of the fade effect.
- Key "fade_modulate" allows you to set the type to make the effect colors softer. (Noticed incorrect operation in CS:S.)
- Key "healthshot_effect" key allows you to enable the healthshot effect. (Only works in CS:GO.)
- Key "fov" allows you to change effect's FOV. (Default value: 90)
- Key "duration" allows you to set the duration of the effect.
- Key "vip" determines whether to add the effect to VIP. (Explanation: if "add_to_vip_by_default" is 1 and "vip" is 0, the effect will not be added).
- Key "shop" determines whether to add the effect to Shop. (Explanation: if "add_to_shop_by_default" is 1 and "shop" is 0, the effect will not be added.)
- Key "shop_description" key allows you to set the product description. (There is support for translations, you can see an example with already added effects and translations).
- Key "shop_price" key allows you to set the price of the product in Shop.
- Key "shop_sellprice" key allows you to set the selling price of the item.
- Key "shop_duration" key allows you to set the duration of the item.
- Key "shop_luckchance" key allows you to set the chance of falling out when testing luck.
- Key "shop_hide" allows you to hide item. (To give via admin menu, or to receive by testing your luck.)

## [1.0.0]

### Added
- **Release!**
