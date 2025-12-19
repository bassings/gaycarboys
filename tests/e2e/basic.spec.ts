import { test, expect } from '@playwright/test';

test('homepage loads', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/Gay Car Boys/i);
});

test('article page loads', async ({ page }) => {
  await page.goto('/');
  const firstPost = page.locator('article').first();
  await firstPost.click();
  await expect(page.locator('article')).toBeVisible();
});


