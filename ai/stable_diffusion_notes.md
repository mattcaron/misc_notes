## Base model considerations

The image generation geometry is determined by the image training size, which is based on what the base model was trained on.

* SD1 = 512 x 512
* SD2 = 768 x 768
* SDXL = 1024 x 1024

Note that you can fudge these slightly, but it's best if at least one dimension is one of the above.

So, for an end target of a 16:9 upscale:

* SD1 = 512 x 288 then scale by 3.75
* SD2 = 768 x 432 then scale by 2.5
* SDXL = 1024 x 576 then scale by 1.875

## On Pony

Many of these specify that their base model is Pony, but not **which** Pony. I'm assuming it's the SD1 Pony, not the rebased SDXL Pony (otherwise, they'd specify PonyXL, right??).

But, also, the tweaks (prompts, etc.) for Pony should work on all the derivatives.

Refs:
* https://civitai.com/articles/2134/aspect-ratios-and-image-sizes-for-stable-diffusion-a1111-an-overview

## Model specific configs

* [AbsoluteReality](https://civitai.com/models/81458)
  * Based on SD1
    * 512 as an anchor geometry
  * Recommendations:
    * CFG: 4.5 - 10
    * Steps: 25 - 30
    * Sampler: DPM++ SDE
    * Scheduler: Karras

* [CyberRealistic Pony](https://civitai.com/models/443821)
  * Based on Pony
    * 512 as an anchor geometry
  * Recommendations:
    * Clip Skip: 2
    * Positive prompt: `score_9, score_8_up, score_7_up, photo, photorealistic`
    * Negative prompt: `score_6, score_5, score_4, source_pony, source_anime, source_furry, source_cartoon, worst quality, low quality`
  
* [DreamShaper XL](https://civitai.com/models/112902)
  * Based on SDXL Turbo
    * 1024 as anchor geometry
  * Recommendations:
    * CFG: 2
    * Steps: 4 - 8
    * Sampler: DPM++ SDE
    * Scheduler: Karras

* [Flux.1
  [schnell]](https://huggingface.co/black-forest-labs/FLUX.1-schnell/tree/main)
  * It's it's own base model. Not sure of image sizes.
  * Recommendations:
    * CFG: 0
    * Steps: 1 - 4

* [Flux Unchained by SCG
  [SchnFu]](https://civitai.com/models/645943?modelVersionId=751510)
  * Base model: Flux.1 Schnell
  * Recommendations:
    * CFG: 1
    * Steps: 4
    * Sampler: Euler
    * Scheduler: Normal or Simple

* [GhostXL](https://civitai.com/models/312431/ghostxl)
  * Base model: SDXL
    * 1024 as anchor geometry
  * Recommendations:
    * Style prompts:
      * `realistic art style`
      * `realistic anime art style`
      * `anime art style`
      * `comic art style`

* [Juggernaut XL](https://civitai.com/models/133005/juggernaut-xl)
  * Base model: SDXL
    * 1024 as anchor geometry
  * Recommendations:
    * Resolution: 832*1216 (For Portrait, but any SDXL Res will work fine)
    * CFG: 3 - 6
    * Steps: 30 - 40
    * Sampler: DPM++ 2M SDE
  * HiRes upscale:
    * 4xNMKD-Siax_200k
    * 15 Steps
    * 0.3 Denoise
    * 1.5 Upscale

* [Lyriel](https://civitai.com/models/22922/lyriel)
  * Base model: SD 1.5
    * 512 as anchor geometry
  * Recommendations:
    * Clip Skip: 2
    * Steps: 25 - 35+
    * Sampler: DPM++ 2M
    * Scheduler: Karras

* [NVJOB Monster Art Generator](https://civitai.com/models/72384/nvjob-monster-art-generator)
  * Base model: SD 1.5
    * 512 as anchor geometry

* [Pony Diffusion V6 XL](https://civitai.com/models/257749)
  * Base model: Pony
    * 1024 anchor resolution (recommended from notes)
  * Recommendations:
    * Clip Skip: 2
    * Steps: 25
    * Sampler: Euler a
    * Positive Prompt: `score_9, score_8_up, score_7_up, score_6_up, score_5_up, score_4_up, what you want, tags`
      * Tags of note:
        * `source_pony`
        * `source_furry`
        * `source_cartoon`
        * `source_anime`
        * `rating_safe`
        * `rating_questionable`
        * `rating_explicit`

* [Pony Realism](https://civitai.com/models/372465)
  * [Reference Compendium](https://civitai.com/articles/6621)
  * Base model: Pony
  * Recommendations:
    * Resolution: 832x1216
    * Clip Skip: 2
    * CFG: 6
    * Steps: 30
    * Sampler: DPM++ SDE
    * Scheduler: Karras
    * Positive prompt: `score_9, score_8_up, score_7_up, (SUBJECT), depth of field, highly detailed, high contrast, film grain, Rim Lighting`
    * Negative prompt: `score_6, score_5, score_4, text, censored, deformed, bad hand`

* [Real Dream](https://civitai.com/models/153568/real-dream)
  * Base model: Pony (SDXL)
    * 1024 anchor resolution
  * Recommendations:
    * Steps: 20 - 30
    * Sampler: Euler a or DPM++ SDE
    * Scheduler: Karras

* [Realistic Vision (Hyper)](https://civitai.com/models/4201?modelVersionId=501240)
  * Base model: SD 1.5 Hyper
    * 512 as anchor geometry
  * Recommendations:
    * CFG: 1.5 - 2
    * Steps: 4-6+
    * Sampler: DPM++ SDE
    * Scheduler: Karras
    * Positive prompt: `RAW photo, your subject goes here, 8k uhd, dslr, soft lighting, high quality, film grain, Fujifilm XT3`
    * Negative prompt:
      * `(deformed iris, deformed pupils, semi-realistic, cgi, 3d, render, sketch, cartoon, drawing, anime), text, cropped, out of frame, worst quality, low quality, jpeg artifacts, ugly, duplicate, morbid, mutilated, extra fingers, mutated hands, poorly drawn hands, poorly drawn face, mutation, deformed, blurry, dehydrated, bad anatomy, bad proportions, extra limbs, cloned face, disfigured, gross proportions, malformed limbs, missing arms, missing legs, extra arms, extra legs, fused fingers, too many fingers, long neck`
      * `(deformed iris, deformed pupils, semi-realistic, cgi, 3d, render, sketch, cartoon, drawing, anime, mutated hands and fingers:1.4), (deformed, distorted, disfigured:1.3), poorly drawn, bad anatomy, wrong anatomy, extra limb, missing limb, floating limbs, disconnected limbs, mutation, mutated, ugly, disgusting, amputation,`

* [RPG v5](https://civitai.com/models/1116)
  * Base model: SD 1.5 Hyper
    * 512 as anchor geometry

* [RPG Rifting in the 90s](https://civitai.com/models/5324/rpg-rifting-in-the-90s)
  * Base model: SD 1.5 Hyper
    * 512 as anchor geometry
  * Recommendations:
    * Trigger is `PBOldRifRPGStyle`

* [RPG 2000's Ink and pencil style character
  generator](https://civitai.com/models/5988/rpg-2000s-ink-and-pencil-style-character-generator)
  * Base model: SD 1.5 Hyper
    * 512 as anchor geometry
  * Trigger is `TheRPGCharGenEsAFArt`, with a recommended weight between 0.5 and 1.12 (e.g. `(TheRPGCharGenEsAFArt:0.7)`)