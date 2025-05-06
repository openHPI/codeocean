# Multilanguage Support for Exercises and Tips

This document provides an overview of how to support multilingual exercise descriptions and tips that are displayed in the exercise implementation view.

## Introduction

To improve the maintenance of exercises in multilingual teaching scenarios, it may be better to provide exercises with exercise descriptions in several languages than to work with translated copies of an exercise. CodeOcean already has multilingual support that can be used to achieve this. 

The implementation of multilanguage support in CodeOcean is inspired by [Moodle's Multilang Content Filter](https://docs.moodle.org/405/en/Multi-language_content_filter): Attributes are used to indicate the multilingual nature of a content element (`class="multilang"`) and to specify the exact language (`lang="XX"`). CSS is then used to control the visibility on the page.

## Usage

When making exercise descriptions or tips multilingual, the `.multilang`class must be assigned to all multilingual content. The `lang` attribute must be set to the appropriate locale, e.g. `"en"` or `"de"`. This very simple solution can be applied in many different ways:

Example 1 (Separated Multilingual Content Blocks):

```
<p class="multilang" lang="de">Implementieren Sie eine Funktion, die für einen gegebenen Parameter entscheidet, ob er gerade oder ungerade ist.</p>
<p class="multilang" lang="en">Implement a function that decides for a given parameter whether it is even or odd.</p>
```

Example 2 (Inline Separation of Multilingual Content):

```
<p><span class="multilang" lang="de">Implementieren Sie eine Funktion, die für einen gegebenen Parameter entscheidet, ob er gerade oder ungerade ist.</span> <span class="multilang" lang="en">Implement a function that decides for a given parameter whether it is even or odd.</span></p>
```

This approach also applies to the description of tips, including their example sections.

## Supported Locales

At the time of writing CodeOcean supports the `DE` and `EN` locales. Accordingly, the two CSS snippets [multilang_de.css](../app/javascript/multilang_de.css) and [multilang_en.css](../app/javascript/multilang_en.css) have been added to the application. To support other locales, just copy &amp; paste one of these snippets and change the locale in the CSS rule. To really take effect, the appropriate locale must be added to CodeOcean (see [Config --> Locales](../config/locales/) for details). 